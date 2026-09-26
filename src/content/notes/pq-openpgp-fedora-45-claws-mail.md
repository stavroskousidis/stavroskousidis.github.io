---
title: "Post-quantum OpenPGP with Claws Mail on Fedora 45 KDE"
description: "Claws Mail PGP/MIME proof of concept using Sequoia Chameleon and patched GPGME, independently verified with RFC 9980 algorithms 30 and 35."
type: "Guide"
status: "Experimental"
published: "2026-09-25"
testedOn:
  - "Fedora 45 KDE Plasma"
  - "Claws Mail 4.4.0"
  - "claws-mail-plugins-pgp 4.4.0"
  - "GPGME 2.0.1-6.rfc9980.1.fc45"
  - "Sequoia Chameleon GnuPG 0.13.1"
tags: [OpenPGP, Post-Quantum, Claws Mail, Sequoia, Fedora, RFC9980]
draft: false
---

This guide covers the Claws Mail part of the Fedora 45 RFC 9980 proof of concept. Complete the [shared setup](/notes/pq-openpgp-fedora-45-base) first.

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

## Runtime evidence

While Claws Mail is running, confirm that the process loads:

```text
/usr/lib64/claws-mail/plugins/pgpcore.so
/usr/lib64/claws-mail/plugins/pgpmime.so
/usr/lib64/libgpgme.so.45.0.1
```

Together with the Chameleon `gpgconf` mapping, this confirms the runtime path:

```text
Claws Mail
  -> PGP/Core + PGP/MIME
  -> GPGME
  -> Sequoia Chameleon
```

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

## Create the three messages

Create:

```text
Unsigned
Signed only
Encrypted + Signed
```

to:

```text
rfc9980-poc@example.invalid
```

Use the default local MH mailbox at:

```text
~/Mail
```

Find the queued messages in:

```text
~/Mail/queue
```

For reference, the successful test used these queue files:

```text
~/Mail/queue/1   Unsigned
~/Mail/queue/4   Signed only
~/Mail/queue/3   Encrypted + Signed
```

The exact numeric filenames are local queue state and should not be assumed in another run.

Confirm that the signed message contains:

```text
X-Claws-Sign:1
Content-Type: multipart/signed
```

Confirm that the encrypted-and-signed message contains:

```text
X-Claws-Sign:1
X-Claws-Encrypt:1
Content-Type: multipart/encrypted
```

Claws queue files contain Claws-specific headers before the actual RFC 5322/MIME message. For independent MIME parsing, strip everything through:

```text
X-Claws-End-Special-Headers: 1
```

and parse the remaining message.

## Independent verification

Inspect the signed-only PGP/MIME signature packet and confirm:

```text
:signature packet: algo 30
digest algo 10
```

Chameleon reported:

```text
using MLDSA65_Ed25519 key ...
GOODSIG
VALIDSIG ... 30 ...
SIGNED_VERIFY_RC=0
```

Inspect the encrypted-and-signed message and confirm:

```text
:pubkey enc packet: version 6, algo 35
:encrypted data packet:
```

and Chameleon identified:

```text
encrypted with MLKEM768_X25519 key ...
```

Decryption succeeded:

```text
DECRYPTION_OKAY
DECRYPT_RC=0
```

Confirm that the decrypted MIME entity contains:

```text
Content-Type: multipart/signed
```

Its inner signature again contained:

```text
:signature packet: algo 30
```

Independently verify the inner signature and confirm:

```text
GOODSIG
VALIDSIG ... 30 ...
INNER_VERIFY_RC=0
```

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
