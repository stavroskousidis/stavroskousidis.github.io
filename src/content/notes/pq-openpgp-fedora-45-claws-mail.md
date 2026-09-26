---
title: "Post-quantum OpenPGP with Claws Mail on Fedora 45 KDE"
description: "Claws Mail PGP/MIME proof of concept using Sequoia Chameleon and patched GPGME, independently verified with RFC 9980 algorithms 30 and 35."
type: "Guide"
status: "Experimental"
published: "2026-09-26"
testedOn:
  - "Fedora 45 KDE Plasma"
  - "Claws Mail 4.4.0"
  - "claws-mail-plugins-pgp 4.4.0"
  - "GPGME 2.0.1-6.rfc9980.1.fc45"
  - "Sequoia Chameleon GnuPG 0.13.1"
tags: [OpenPGP, Post-Quantum, Claws Mail, Sequoia, Fedora, RFC9980]
draft: false
---

This guide covers the Claws Mail-specific part of the Fedora 45 RFC 9980 proof of concept. Complete the [shared setup](/notes/pq-openpgp-fedora-45-base) first, including the patched GPGME installation, Chameleon command selection, and disposable test certificate import and authorization.

Claws Mail uses its PGP plugins through GPGME:

```text
Claws Mail
  -> PGP/Core + PGP/MIME
  -> patched GPGME
  -> Sequoia Chameleon
  -> Sequoia OpenPGP / Keystore
```

Unlike Evolution, Claws Mail is therefore part of the GPGME-based test path.

## Install Claws Mail and the PGP plugins

Install the packages on Fedora 45 KDE:

```console
sudo dnf install -y \
  claws-mail \
  claws-mail-plugins-pgp
```

Verify that your package versions match or supersede this tested baseline:

```text
claws-mail-4.4.0-8.fc45.x86_64
claws-mail-plugins-pgp-4.4.0-8.fc45.x86_64
gpgme-2.0.1-6.rfc9980.1.fc45.x86_64
```

In **Configuration -> Plugins**, load:

```text
PGP/Core
PGP/MIME
```

Use PGP/MIME for the test identity.

## Start Claws Mail and verify the runtime stack

Use the same terminal in which you set the compatibility `PATH` in the shared setup. Close any existing Claws Mail instance before continuing.

Confirm the selected OpenPGP command and patched GPGME package:

```console
command -v gpg
gpgconf --list-components | grep -E '^(gpg:|gpgsm:)'
rpm -q gpgme
```

Start Claws Mail once from this terminal and keep this instance open for the remaining steps:

```console
claws-mail >/tmp/rfc9980-claws.log 2>&1 &
CLAWS_PID=$!
sleep 5
kill -0 "$CLAWS_PID"
```

If the last command fails, inspect `/tmp/rfc9980-claws.log` and check whether an earlier Claws Mail instance was still running.

After loading **PGP/Core** and **PGP/MIME**, inspect the libraries and plugins loaded by this process:

```console
grep -E \
  'pgpcore\.so|pgpmime\.so|libgpgme\.so' \
  "/proc/$CLAWS_PID/maps" \
  | awk '{print $6}' \
  | sort -u
```

The tested runtime loaded:

```text
/usr/lib64/claws-mail/plugins/pgpcore.so
/usr/lib64/claws-mail/plugins/pgpmime.so
/usr/lib64/libgpgme.so.45.0.1
```

Together with the package and `gpgconf` checks, this establishes the GPGME-based Chameleon path used by the test.

## Configure the test account

Use:

```text
Display name: RFC9980 PoC
Email:        rfc9980-poc@example.invalid
```

For the outgoing test transport:

```text
SMTP server: localhost
Authentication: none
Encryption: none
```

No working SMTP server is required; the goal is to let Claws construct and queue the complete MIME message locally.

Choose PGP/MIME as the privacy system and select the RFC 9980 test certificate.

> **Short configuration note:** Select the intended Claws Mail account in the compose window. Choosing the wrong default account causes signing to fail even when the OpenPGP implementation works correctly.

## Create and locate the three messages

Create three messages to:

```text
rfc9980-poc@example.invalid
```

using:

```text
Unsigned
Signed only
Encrypted + signed
```

The tested configuration used Claws Mail's local MH mailbox at `$HOME/Mail`. If your account uses a different mailbox location, use that configured location instead.

For the tested layout, set:

```console
MAILBOX="$HOME/Mail"
QUEUE="$MAILBOX/queue"
test -d "$QUEUE"
```

List the queue files in modification-time order:

```console
find "$QUEUE" -maxdepth 1 -type f -printf '%T@ %p\n' \
  | sort -nr
```

Do not assume numeric queue filenames from another run. Match the test messages by their subjects and Claws-specific headers. A signed queue file contains:

```text
X-Claws-Sign:1
```

and an encrypted-and-signed queue file contains:

```text
X-Claws-Sign:1
X-Claws-Encrypt:1
```

Record the full paths and create one verification directory:

```console
SIGNED="SIGNED_QUEUE_FILE"
ENCRYPTED="ENCRYPTED_QUEUE_FILE"
WORK="$HOME/rfc9980-mail-test/claws-verify"
export SIGNED ENCRYPTED WORK

rm -rf "$WORK"
mkdir -p "$WORK"
```

Claws queue files contain private queue headers before the RFC 5322/MIME message. Strip those headers before MIME parsing:

```console
python3 - <<'PY'
from pathlib import Path
import os

work = Path(os.environ["WORK"])
for name, env in [("signed.eml", "SIGNED"), ("encrypted.eml", "ENCRYPTED")]:
    raw = Path(os.environ[env]).read_bytes()
    marker = b"X-Claws-End-Special-Headers: 1"
    pos = raw.find(marker)
    assert pos >= 0, f"{env}: Claws special-header terminator not found"
    pos = raw.find(b"\n", pos)
    assert pos >= 0, f"{env}: malformed queue headers"
    work.joinpath(name).write_bytes(raw[pos + 1:].lstrip(b"\r\n"))
PY
```

Confirm the resulting MIME types:

```console
grep -m1 '^Content-Type:' "$WORK/signed.eml"
grep -m1 '^Content-Type:' "$WORK/encrypted.eml"
```

The expected outer types are `multipart/signed` and `multipart/encrypted`, respectively.

## Independent verification

Extract and verify the signed-only PGP/MIME message:

```console
python3 - <<'PY'
from email import policy
from email.parser import BytesParser
from pathlib import Path
import os

work = Path(os.environ["WORK"])
m = BytesParser(policy=policy.SMTP).parsebytes(work.joinpath("signed.eml").read_bytes())
parts = list(m.iter_parts())
assert len(parts) >= 2, "Signed message does not have expected MIME parts"
work.joinpath("signed-content.txt").write_bytes(parts[0].as_bytes(policy=policy.SMTP))
work.joinpath("signed-signature.asc").write_bytes(parts[1].get_payload(decode=True))
PY

gpg --list-packets "$WORK/signed-signature.asc"

gpg --status-fd=1 \
  --verify "$WORK/signed-signature.asc" "$WORK/signed-content.txt"
```

Confirm a signature packet using algorithm `30`, followed by `GOODSIG` and `VALIDSIG ... 30 ...` with exit status `0`.

Extract the encrypted OpenPGP payload:

```console
python3 - <<'PY'
from email import policy
from email.parser import BytesParser
from pathlib import Path
import os

work = Path(os.environ["WORK"])
m = BytesParser(policy=policy.SMTP).parsebytes(work.joinpath("encrypted.eml").read_bytes())
parts = list(m.iter_parts())
assert len(parts) >= 2, "Encrypted message does not have expected MIME parts"
work.joinpath("encrypted.pgp").write_bytes(parts[1].get_payload(decode=True))
PY

gpg --list-packets "$WORK/encrypted.pgp"

gpg --status-fd=1 \
  --output "$WORK/decrypted.eml" \
  --decrypt "$WORK/encrypted.pgp"
```

Confirm a version-6 public-key encrypted session key packet using algorithm `35` and a successful `DECRYPTION_OKAY`.

The decrypted MIME entity is signed. Extract and verify its inner signature:

```console
python3 - <<'PY'
from email import policy
from email.parser import BytesParser
from pathlib import Path
import os

work = Path(os.environ["WORK"])
m = BytesParser(policy=policy.SMTP).parsebytes(work.joinpath("decrypted.eml").read_bytes())
parts = list(m.iter_parts())
assert len(parts) >= 2, "Decrypted message is not multipart/signed"
work.joinpath("inner-content.txt").write_bytes(parts[0].as_bytes(policy=policy.SMTP))
work.joinpath("inner-signature.asc").write_bytes(parts[1].get_payload(decode=True))
PY

gpg --list-packets "$WORK/inner-signature.asc"

gpg --status-fd=1 \
  --verify "$WORK/inner-signature.asc" "$WORK/inner-content.txt"
```

Confirm another algorithm-`30` signature with `GOODSIG`, `VALIDSIG`, and exit status `0`.

## Result

The procedure exercises this path:

```text
Claws Mail
  -> PGP/Core + PGP/MIME
  -> patched GPGME
  -> Sequoia Chameleon
  -> Sequoia OpenPGP / Keystore
```

with:

```text
Signing:
  ML-DSA-65+Ed25519
  OpenPGP algorithm 30
  independent verification successful

Encryption:
  ML-KEM-768+X25519
  OpenPGP algorithm 35
  version-6 PKESK
  independent decryption successful
  inner signature independently valid
```

This proof of concept requires no Claws Mail source patch.

Select the correct account in the compose window; an account-selection error is a configuration issue and does not form part of the cryptographic result.
