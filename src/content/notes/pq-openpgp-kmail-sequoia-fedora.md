---
title: "Post-quantum OpenPGP with KMail and Sequoia Chameleon on Fedora"
description: "A reproducible KMail setup for signing and encrypting OpenPGP mail with ML-DSA-65+Ed25519 and ML-KEM-768+X25519."
type: "Guide"
status: "Experimental"
published: "2026-09-24"
updated: "2026-09-24"
testedOn:
  - "Fedora 45"
  - "KMail 26.08.1"
  - "GPGME 2.0.1"
  - "Sequoia Chameleon GnuPG 0.13.1"
  - "sequoia-openpgp 2.4.1"
  - "sequoia-sq 1.4.1"
tags:
  - "OpenPGP"
  - "Post-Quantum"
  - "KMail"
  - "Sequoia"
  - "Fedora"
draft: false
---

This guide records a reproducible proof-of-concept setup for using hybrid post-quantum OpenPGP with KMail on Fedora.

The tested configuration uses:

- ML-DSA-65 combined with Ed25519 for signatures;
- ML-KEM-768 combined with X25519 for encryption;
- Sequoia Chameleon as the GnuPG-compatible OpenPGP engine; and
- a patched GPGME build that recognizes the corresponding OpenPGP algorithm identifiers.

The setup is deliberately marked **experimental**. It is intended for technical evaluation of desktop-client integration. The underlying post-quantum OpenPGP algorithms are implemented by Sequoia; the purpose of this setup is to make that implementation usable through KMail's normal GPGME-based OpenPGP path.

## Goal

Configure KMail so that a normal PGP/MIME message can be:

1. signed using ML-DSA-65+Ed25519;
2. encrypted using ML-KEM-768+X25519;
3. queued through KMail's normal Akonadi mail infrastructure; and
4. independently decrypted and verified using the packaged Sequoia Chameleon engine.

The tested OpenPGP algorithm identifiers are:

- `30`: ML-DSA-65+Ed25519;
- `35`: ML-KEM-768+X25519.

## Test environment

The final end-to-end test was performed on a clean Fedora 45 virtual machine.

For KMail, Fedora KDE Plasma is the preferred baseline because KMail is part of the KDE PIM stack. KMail also works on Fedora Workstation with GNOME, but installing it there pulls in a substantial part of the KDE PIM and Qt infrastructure.

The clean-VM test described here used:

```text
Fedora 45
KMail 26.08.1
GPGME 2.0.1
GPGME++ 2.0.0
QGpgME Qt6 2.0.0
Sequoia Chameleon GnuPG 0.13.1
sequoia-openpgp 2.4.1
sequoia-sq 1.4.1
```

## Architecture

The tested path is:

```text
KMail
  -> QGpgME
  -> GPGME++
  -> patched GPGME
  -> gpgconf compatibility wrapper
  -> Sequoia Chameleon
  -> Sequoia OpenPGP / Keystore
```

The Fedora GnuPG installation remains installed.

In particular, the proof-of-concept package does **not** replace `/usr/bin/gpg` globally. Instead, it provides an isolated compatibility environment below:

```text
/usr/libexec/rfc9980-openpgp/
```

Within that environment:

```text
gpg   -> Sequoia Chameleon
gpgv  -> Sequoia Chameleon
gpgsm -> Fedora GnuPG
```

This keeps S/MIME on Fedora's normal `gpgsm` implementation while routing OpenPGP operations through Chameleon.

## Install the proof-of-concept packages

The tested RPMs are available from Fedora COPR.

Enable the repository:

```console
sudo dnf copr enable stavroskousidis/rfc9980-openpgp-poc
```

Install the Sequoia Chameleon proof-of-concept package:

```console
sudo dnf install -y \
  sequoia-chameleon-rfc9980-poc
```

Fedora 45 already installs `gpgme` as part of the normal desktop stack. A plain `dnf install gpgme` therefore does not necessarily switch an existing Fedora installation to the patched COPR build.

Upgrade `gpgme` explicitly from the COPR repository:

```console
sudo dnf upgrade -y \
  --allow-vendor-change \
  --repo="copr:copr.fedorainfracloud.org:stavroskousidis:rfc9980-openpgp-poc" \
  gpgme
```

Verify the installed packages:

```console
rpm -q \
  gpgme \
  sequoia-chameleon-rfc9980-poc
```

The tested versions are:

```text
gpgme-2.0.1-6.rfc9980.1.fc45.x86_64
sequoia-chameleon-rfc9980-poc-0.13.1-0.rfc9980poc.1.fc45.x86_64
```

## Install Sequoia `sq`

Install the Sequoia command-line frontend:

```console
sudo dnf install -y sequoia-sq
```

Record the installed package version:

```console
rpm -q sequoia-sq
```

The tested Fedora 45 build is:

```text
sequoia-sq-1.4.1-1.fc45.x86_64
```

Confirm that the required post-quantum algorithms are exposed by `sq`:

```console
sq key generate --help | \
  grep -E 'mldsa65-ed25519|mlkem768-x25519'
```

The output should contain both:

```text
mldsa65-ed25519
mlkem768-x25519
```

## Activate the Sequoia OpenPGP environment

Installing the RPMs does not replace Fedora's system-wide GnuPG commands. The proof-of-concept environment is activated explicitly for the shell or application that should use Sequoia Chameleon.

Activate it in the current shell:

```console
export PATH="/usr/libexec/rfc9980-openpgp/bin:/usr/bin:/bin"
```

Confirm which commands are selected:

```console
command -v gpg
command -v gpgconf
command -v gpgsm
```

The expected paths are:

```text
/usr/libexec/rfc9980-openpgp/bin/gpg
/usr/libexec/rfc9980-openpgp/bin/gpgconf
/usr/bin/gpgsm
```

Check the Chameleon version:

```console
gpg --version
```

The tested build reports:

```text
gpg (GnuPG-compatible Sequoia Chameleon) 2.2.40
Sequoia gpg Chameleon 0.13.1
sequoia-openpgp 2.4.1
```

The supported algorithm list should include at least:

```text
MLDSA65_Ed25519
MLKEM768_X25519
```

Inspect the component mapping:

```console
gpgconf --list-components
```

The relevant lines should include:

```text
gpg:OpenPGP:/usr/libexec/rfc9980-openpgp/bin/gpg
gpgsm:S/MIME:/usr/bin/gpgsm
```

Other Fedora GnuPG components remain available, for example:

```text
gpg-agent:Private Keys:/usr/bin/gpg-agent
dirmngr:Network:/usr/bin/dirmngr
pinentry:Passphrase Entry:/usr/bin/pinentry
```

This activation only affects the shell and applications started from it. Fedora's normal `/usr/bin/gpg` remains installed and unchanged.

Do not override `HOME`, `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`, `XDG_STATE_HOME` or `GNUPGHOME` for KMail. KMail and Akonadi should remain in the normal desktop session.

The `sq` command itself does not require this activation: `sq` is already a Sequoia-native command. The compatibility environment is needed for applications such as KMail that expect a GnuPG-compatible OpenPGP engine.

## Create a post-quantum test key

Create a dedicated directory for the test:

```console
WORK="$HOME/rfc9980-kmail-test"
mkdir -p "$WORK"
cd "$WORK"
```

Generate a short-lived disposable test identity:

```console
sq key generate \
  --own-key \
  --name "RFC9980 PoC" \
  --email "rfc9980-poc@example.invalid" \
  --profile rfc9580 \
  --cipher-suite mldsa65-ed25519 \
  --encryption-algorithm mlkem768-x25519 \
  --expiration 1d \
  --without-password \
  --output rfc9980-secret.pgp \
  --rev-cert rfc9980.rev
```

For production keys, use a password-protected secret key and an appropriate validity period. The passwordless key above is only suitable for a disposable local integration test.

Inspect it:

```console
sq inspect rfc9980-secret.pgp
```

A typical result contains:

```text
Public-key algo: ML-DSA-65+Ed25519
Key flags: certification

Public-key algo: ML-DSA-65+Ed25519
Key flags: signing

Public-key algo: ML-DSA-65+Ed25519
Key flags: authentication

Public-key algo: ML-KEM-768+X25519
Key flags: transport encryption, data-at-rest encryption
```

The authentication subkey is generated by `sq` as part of this key profile but is not used by the KMail tests below.

## Import the key into Sequoia

Import the secret key into the Sequoia Keystore and certificate store:

```console
sq key import rfc9980-secret.pgp
```

Record the fingerprint printed by `sq`, then authorize the local test certificate:

```console
sq pki link authorize \
  --unconstrained \
  --cert=YOUR_FINGERPRINT \
  --all
```

Replace `YOUR_FINGERPRINT` with the complete certificate fingerprint.

Confirm that Sequoia sees it:

```console
sq cert list YOUR_FINGERPRINT
```

There is no need to import the public certificate separately through `gpg`; `sq key import` has already made the certificate available to the Sequoia-backed environment.

## Verify the algorithms through Chameleon

With the Sequoia compatibility environment still active, list the certificate through Chameleon:

```console
gpg --with-colons --list-keys YOUR_FINGERPRINT
```

The relevant records should look like:

```text
pub:...:30:...
sub:...:30:...:s
sub:...:30:...:a
sub:...:35:...:e
```

Algorithm `30` is the ML-DSA-65+Ed25519 construction and algorithm `35` is ML-KEM-768+X25519.

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

The clean Fedora 45 test used:

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

Start KMail from the same shell in which the compatibility environment was activated:

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

The tested runtime loaded:

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

In the identity's cryptography settings, select the post-quantum OpenPGP certificate generated above for signing and encryption.

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

with both signing and encryption disabled.

Queue it.

The resulting Outbox message should have an ordinary content type such as:

```text
Content-Type: text/plain; charset="utf-8"
```

This verifies the KMail, Akonadi and Outbox configuration independently of OpenPGP.

## Test signing

Compose another message to the same recipient with OpenPGP signing enabled and encryption disabled.

Queue it.

The Outbox message should use PGP/MIME:

```text
Content-Type: multipart/signed;
 protocol="application/pgp-signature"
```

## Test signing and encryption

Compose a third message to the same recipient with both OpenPGP signing and encryption enabled.

Queue it.

The outer message should use PGP/MIME encryption:

```text
Content-Type: multipart/encrypted;
 protocol="application/pgp-encrypted"
```

## Locate the Outbox messages

On the tested Fedora 45 setup, the normal local Outbox is:

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

## Independently verify the signed message

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

The tested signature contains:

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

The successful Fedora 45 test reported:

```text
gpg: using MLDSA65_Ed25519 key ...
[GNUPG:] GOODSIG ...
[GNUPG:] VALIDSIG ... 30 ...
```

and returned status `0`.

## Independently verify the encrypted message

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

The tested message contains:

```text
:pubkey enc packet: version 6, algo 35
```

Decrypt it:

```console
gpg --status-fd=1 \
  --output "$WORK/decrypted.eml" \
  --decrypt "$WORK/encrypted.pgp"
```

The successful test reported:

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

The tested result contains:

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

The successful test reported:

```text
gpg: using MLDSA65_Ed25519 key ...
[GNUPG:] GOODSIG ...
[GNUPG:] VALIDSIG ... 30 ...
```

and returned status `0`.

## What the clean-VM test demonstrated

The Fedora 45 test demonstrated the following complete path:

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

## What the GPGME patch changes

The proof-of-concept GPGME package adds explicit identifiers for the post-quantum OpenPGP public-key algorithms used by the current specifications.

The patch recognizes:

```text
30  ML-DSA-65+Ed25519
31  ML-DSA-87+Ed448
32  SLH-DSA-SHAKE-128s
33  SLH-DSA-SHAKE-128f
34  SLH-DSA-SHAKE-256s
35  ML-KEM-768+X25519
36  ML-KEM-1024+X448
```

For the KMail test described here, algorithms `30` and `35` are exercised.

The patch has been submitted upstream for discussion. The packaged version deliberately preserves the working proof-of-concept behavior used for the tests in this note.

## What the Chameleon package changes

The Chameleon package is installed alongside Fedora GnuPG and does not overwrite Fedora-owned `gpg`, `gpgv`, `gpgconf` or `gpgsm` binaries.

Its isolated environment provides:

```text
/usr/libexec/rfc9980-openpgp/gpg-sq
/usr/libexec/rfc9980-openpgp/gpgv-sq
/usr/libexec/rfc9980-openpgp/bin/gpg
/usr/libexec/rfc9980-openpgp/bin/gpgv
/usr/libexec/rfc9980-openpgp/bin/gpgconf
```

The `gpgconf` wrapper directs OpenPGP operations to Chameleon while keeping S/MIME on Fedora's normal `gpgsm`.

The packaged Chameleon build uses the OpenSSL crypto backend.

## Password-protected keys

The packaged Chameleon build also contains experimental support for password-protected keys stored in the Sequoia Keystore.

For such keys, Chameleon can use the configured `gpg-agent` to launch Pinentry, receive the passphrase and pass it to the corresponding Sequoia Keystore softkey. The Keystore operation is then retried with the unlocked key.

This preserves the familiar graphical Pinentry workflow while the actual OpenPGP private-key operation is performed through Sequoia.

The architecture remains transitional: a future backend design should ideally allow authentication and secret handling to remain entirely inside the backend rather than passing the authentication secret through the compatibility layer.

## Revert the KMail test environment

Because no Fedora system binaries are replaced, reverting the runtime selection is simple.

Close KMail and open a fresh shell without the modified `PATH`, or reset it explicitly.

Verify:

```console
command -v gpg
command -v gpgconf
command -v gpgsm
```

The normal Fedora commands should again resolve below `/usr/bin`.

The Chameleon proof-of-concept package can be removed with:

```console
sudo dnf remove sequoia-chameleon-rfc9980-poc
```

If the patched GPGME package is no longer required, disable the COPR repository and synchronize back to Fedora's package:

```console
sudo dnf copr disable stavroskousidis/rfc9980-openpgp-poc
sudo dnf distro-sync gpgme
```

Review the proposed transaction before accepting it.

## Current limitations

This remains a proof of concept.

The successful tests establish that KMail can use the Sequoia-based RFC 9980 implementation through GPGME and Chameleon to:

- recognize the hybrid certificate;
- sign using ML-DSA-65+Ed25519;
- encrypt using ML-KEM-768+X25519;
- create standard PGP/MIME messages; and
- independently decrypt and verify those messages.

They do not establish that other desktop mail clients or middleware stacks can use the same RFC 9980 algorithms through their respective OpenPGP integration layers. Client support remains an application-level integration question rather than a limitation of the underlying Sequoia implementation.

Successful command-line parsing alone is not sufficient evidence of desktop-client integration. The application, middleware API, key store and private-key backend must all support the required operations.

## Next steps

Follow-up work will cover:

- Claws Mail integration;
- Evolution integration;
- password-protected production keys; and
- further work on the GPGME and Keystore architecture.
