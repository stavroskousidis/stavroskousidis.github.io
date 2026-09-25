---
title: "Post-quantum OpenPGP with KMail on Fedora 45 KDE"
description: "KMail-specific setup, PGP/MIME tests and independently verified hybrid post-quantum packets."
type: "Guide"
status: "Experimental"
published: "2026-09-25"
updated: "2026-09-25"
testedOn:
  - "Fedora 45 KDE Plasma"
  - "KMail 26.08.1"
  - "GPGME 2.0.1 with experimental RFC 9980 patch"
  - "Sequoia Chameleon GnuPG 0.13.1"
tags: [OpenPGP, Post-Quantum, KMail, Sequoia, Fedora]
draft: false
---

This guide covers the KMail-specific part of the Fedora 45 proof of concept. Complete the [shared setup](/notes/pq-openpgp-fedora-45-base) first: install the experimental packages, select the compatibility environment, create or import the disposable test certificate, and authorize it. Use the separate base guide for the steps shared with Claws Mail and Evolution.

```text
KMail → QGpgME → GPGME++ → patched GPGME
      → gpgconf compatibility wrapper → Sequoia Chameleon
      → Sequoia OpenPGP / Keystore
```

Use ML-DSA-65+Ed25519 (algorithm 30) for signing and ML-KEM-768+X25519 (algorithm 35) for encryption. The final sections show how to inspect and independently verify the resulting PGP/MIME messages.

## Install KMail

Install KMail using Fedora's normal package:

```console
sudo dnf install -y kmail
```

Do not explicitly install `qgpgme-qt6` or `gpgmepp`. They are normal KMail dependencies and are installed automatically by Fedora.

Verify the relevant packages:

```console
rpm -q \
  kmail \
  kmail-libs \
  gpgme \
  gpgmepp \
  qgpgme-qt6 \
  libkleo \
  akonadi-server
```

Verify that your package versions match or supersede this tested baseline:

```text
kmail-26.08.1-1.fc45.x86_64
kmail-libs-26.08.1-1.fc45.x86_64
gpgme-2.0.1-6.rfc9980.1.fc45.x86_64
gpgmepp-2.0.0-2.fc45.x86_64
qgpgme-qt6-2.0.0-4.fc45.x86_64
libkleo-26.08.1-1.fc45.x86_64
akonadi-server-26.08.1-1.fc45.x86_64
```

## Start KMail in the Sequoia environment

Start KMail from the same shell in which you activated the compatibility environment:

```console
kmail
```

KMail, Akonadi, D-Bus, Wayland and the local mail folders should all continue to use the normal desktop session.

Only the OpenPGP command path is changed.

## Verify the KMail runtime stack

Before configuring the test identity, verify that KMail actually loads the patched GPGME stack.

Start KMail in the background:

```console
kmail >/tmp/rfc9980-kmail.log 2>&1 &
KMAIL_PID=$!
sleep 8
```

Confirm that it is still running:

```console
kill -0 "$KMAIL_PID"
```

Inspect the loaded crypto libraries:

```console
grep -E \
  'libgpgme\.so|libgpgmepp\.so|libqgpgme' \
  "/proc/$KMAIL_PID/maps" \
  | awk '{print $6}' \
  | sort -u
```

Confirm that the process loads:

```text
/usr/lib64/libgpgme.so.45.0.1
/usr/lib64/libgpgmepp.so.7.0.0
/usr/lib64/libqgpgmeqt6.so.15v2.7.0
```

Together with:

```console
gpgconf --list-components | grep -E '^(gpg:|gpgsm:)'
```

this verifies the effective runtime path:

```text
KMail
  -> QGpgME
  -> GPGME++
  -> patched GPGME
  -> Sequoia Chameleon
```

while S/MIME continues to use Fedora's `gpgsm`.

## Configure a KMail test identity

Create a dedicated test identity, for example:

```text
Name:  RFC9980 PoC
Email: rfc9980-poc@example.invalid
```

In the identity's cryptography settings, select the post-quantum OpenPGP certificate that you generated during the shared setup for signing and encryption.

Use KMail's normal `Local Folders` resource for Drafts, Sent and Outbox. No additional Maildir or isolated Akonadi instance is required.

If KMail requires an outgoing transport before it will queue a message, create a deliberately non-functional local SMTP transport for the test, for example:

```text
Name: RFC9980 Test
Server: localhost
Port: 25
Authentication: none
Encryption: none
```

The purpose is only to let KMail construct the message and place it in Outbox. A working SMTP server is not required for the cryptographic test.

## Test unsigned mail

Compose a message to:

```text
rfc9980-poc@example.invalid
```

Disable both signing and encryption.

Queue it.

The resulting Outbox message should have an ordinary content type such as:

```text
Content-Type: text/plain; charset="utf-8"
```

This verifies the KMail, Akonadi and Outbox configuration independently of OpenPGP.

## Test signing

Compose another message to the same recipient. Enable OpenPGP signing and disable encryption.

Queue it.

The Outbox message should use PGP/MIME:

```text
Content-Type: multipart/signed;
 protocol="application/pgp-signature"
```

## Test signing and encryption

Compose a third message to the same recipient. Enable both OpenPGP signing and encryption.

Queue it.

The outer message should use PGP/MIME encryption:

```text
Content-Type: multipart/encrypted;
 protocol="application/pgp-encrypted"
```

## Locate the Outbox messages

Locate the normal local Outbox at:

```text
~/.local/share/akonadi_maildir_resource_0/outbox
```

The newest messages can be inspected with:

```console
OUTBOX="$HOME/.local/share/akonadi_maildir_resource_0/outbox"

find "$OUTBOX" \( -path '*/new/*' -o -path '*/cur/*' \) -type f \
  -printf '%T@ %p\n' \
  | sort -nr \
  | head
```

Inspect the headers of the three messages and note their filenames.

## Independent message verification

You can also use the following recipe on complete raw MIME messages exported from Claws Mail or Evolution. Substitute the message paths and verification directory as appropriate.

### Verify the signed message

Replace `SIGNED_MESSAGE` with the full path of the signed-only Outbox message:

```console
SIGNED="SIGNED_MESSAGE"
export SIGNED
WORK=/tmp/rfc9980-kmail-verify

rm -rf "$WORK"
mkdir -p "$WORK"
```

Extract the detached PGP/MIME signature and the signed MIME part. PGP/MIME signatures are computed over MIME content using canonical CRLF line endings:

```console
python3 - <<'PY'
from email import policy
from email.parser import BytesParser
from pathlib import Path
import os

signed = Path(os.environ["SIGNED"])
work = Path("/tmp/rfc9980-kmail-verify")

m = BytesParser(policy=policy.SMTP).parsebytes(signed.read_bytes())
parts = list(m.iter_parts())
assert len(parts) >= 2, "Signed message does not have expected MIME parts"

work.joinpath("signed-content.txt").write_bytes(
    parts[0].as_bytes(policy=policy.SMTP)
)
work.joinpath("signed-signature.asc").write_bytes(
    parts[1].get_payload(decode=True)
)
PY
```

Inspect the signature packet:

```console
gpg --list-packets "$WORK/signed-signature.asc"
```

Confirm that the signature contains:

```text
:signature packet: algo 30
```

Verify it:

```console
gpg --status-fd=1 \
  --verify \
  "$WORK/signed-signature.asc" \
  "$WORK/signed-content.txt"
```

A successful verification reports:

```text
gpg: using MLDSA65_Ed25519 key ...
[GNUPG:] GOODSIG ...
[GNUPG:] VALIDSIG ... 30 ...
```

and returned status `0`.

### Verify the encrypted message

Replace `ENCRYPTED_MESSAGE` with the full path of the signed-and-encrypted Outbox message:

```console
ENCRYPTED="ENCRYPTED_MESSAGE"
export ENCRYPTED
```

Extract the encrypted OpenPGP payload:

```console
python3 - <<'PY'
from email import policy
from email.parser import BytesParser
from pathlib import Path
import os

encrypted = Path(os.environ["ENCRYPTED"])
work = Path("/tmp/rfc9980-kmail-verify")

m = BytesParser(policy=policy.SMTP).parsebytes(encrypted.read_bytes())
parts = list(m.iter_parts())
assert len(parts) >= 2, "Encrypted message does not have expected MIME parts"

work.joinpath("encrypted.pgp").write_bytes(
    parts[1].get_payload(decode=True)
)
PY
```

Inspect the packet:

```console
gpg --list-packets "$WORK/encrypted.pgp"
```

Confirm that the message contains:

```text
:pubkey enc packet: version 6, algo 35
```

Decrypt it:

```console
gpg --status-fd=1 \
  --output "$WORK/decrypted.eml" \
  --decrypt "$WORK/encrypted.pgp"
```

A successful decryption reports:

```text
[GNUPG:] ENC_TO ... 35 0
gpg: encrypted with MLKEM768_X25519 key ...
[GNUPG:] DECRYPTION_OKAY
```

The decrypted MIME entity is itself signed:

```console
grep -m1 '^Content-Type:' "$WORK/decrypted.eml"
```

The expected result is:

```text
Content-Type: multipart/signed;
```

Extract the inner signature:

```console
python3 - <<'PY'
from email import policy
from email.parser import BytesParser
from pathlib import Path

work = Path("/tmp/rfc9980-kmail-verify")
m = BytesParser(policy=policy.SMTP).parsebytes(
    work.joinpath("decrypted.eml").read_bytes()
)
parts = list(m.iter_parts())
assert len(parts) >= 2, "Decrypted message is not multipart/signed"

work.joinpath("inner-content.txt").write_bytes(
    parts[0].as_bytes(policy=policy.SMTP)
)
work.joinpath("inner-signature.asc").write_bytes(
    parts[1].get_payload(decode=True)
)
PY
```

Inspect the inner signature:

```console
gpg --list-packets "$WORK/inner-signature.asc"
```

Confirm that the result contains:

```text
:signature packet: algo 30
```

Verify it:

```console
gpg --status-fd=1 \
  --verify \
  "$WORK/inner-signature.asc" \
  "$WORK/inner-content.txt"
```

A successful verification reports:

```text
gpg: using MLDSA65_Ed25519 key ...
[GNUPG:] GOODSIG ...
[GNUPG:] VALIDSIG ... 30 ...
```

and returned status `0`.

## Result

The procedure exercises this complete path:

```text
KMail
  -> QGpgME
  -> GPGME++
  -> patched GPGME
  -> Sequoia Chameleon
  -> Sequoia Keystore
```

For signing:

```text
OpenPGP algorithm: 30
Construction: ML-DSA-65+Ed25519
KMail PGP/MIME creation: successful
Independent verification: successful
```

For encryption:

```text
OpenPGP algorithm: 35
Construction: ML-KEM-768+X25519
OpenPGP packet version: 6
KMail PGP/MIME creation: successful
Independent decryption: successful
Inner signature verification: successful
```

This establishes that KMail can use the Sequoia-based RFC 9980 implementation through GPGME and Chameleon to create and process post-quantum OpenPGP mail.

## Scope and next guides

This procedure demonstrates successful KMail integration on Fedora 45 KDE. Use only a short-lived, passwordless key for this test. The isolated compatibility package leaves Fedora's system `gpg` and `gpgsm` intact. See the [shared setup](/notes/pq-openpgp-fedora-45-base) for the exact package versions, Sequoia import and trust commands, the transitional agent/Pinentry architecture, and how to leave the test environment. See [Claws Mail](/notes/pq-openpgp-fedora-45-claws-mail) and [Evolution](/notes/pq-openpgp-fedora-45-evolution) for the other independently verified client paths.
