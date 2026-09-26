---
title: "Post-quantum OpenPGP with Evolution on Fedora 45 GNOME"
description: "Evolution RFC 9980 proof of concept using Camel's GnuPG-compatible CLI integration and Sequoia Chameleon, with stock Fedora GPGME."
type: "Guide"
status: "Experimental"
published: "2026-09-25"
updated: "2026-09-26"
testedOn:
  - "Fedora 45 GNOME"
  - "Evolution 3.62.0"
  - "Evolution Data Server 3.62.0"
  - "GPGME 2.0.1-6.fc45 (stock Fedora)"
  - "Sequoia Chameleon GnuPG 0.13.1"
  - "sequoia-openpgp 2.4.1"
  - "sequoia-sq 1.4.1"
tags: [OpenPGP, Post-Quantum, Evolution, Sequoia, Fedora, RFC9980]
draft: false
---

This guide covers the Evolution-specific part of the Fedora 45 RFC 9980 proof of concept. Complete the [shared setup](/notes/pq-openpgp-fedora-45-base) first.

Evolution is architecturally different from KMail and Claws Mail. Its OpenPGP path uses Camel's GnuPG-compatible command-line integration rather than the GPGME path exercised by the other two clients:

```text
Evolution
  -> Camel OpenPGP
  -> GnuPG-compatible CLI
  -> Sequoia Chameleon
  -> Sequoia OpenPGP / Keystore
```

The runtime checks below confirm this distinction.

## Test environment

```text
Fedora 45 GNOME
Evolution 3.62.0
Evolution Data Server 3.62.0
GPGME 2.0.1-6.fc45
Sequoia Chameleon 0.13.1
sequoia-openpgp 2.4.1
sequoia-sq 1.4.1
```

Install Evolution:

```console
sudo dnf install -y evolution
```

## Stock GPGME is sufficient

Remove the experimental GPGME patch and restore Fedora's stock package:

```console
sudo dnf copr disable stavroskousidis/rfc9980-openpgp-poc

sudo dnf distro-sync -y \
  --allow-vendor-change \
  gpgme
```

Confirm that Fedora installed:

```text
gpgme-2.0.1-6.fc45.x86_64
```

This operation leaves the Chameleon package installed.

This is an important result: Evolution's successful RFC 9980 signing and encryption did not require the proof-of-concept GPGME algorithm patch.

## Start Evolution in the Chameleon environment

```console
export PATH="/usr/libexec/rfc9980-openpgp/bin:/usr/bin:/bin"

evolution >/tmp/evolution-rfc9980.log 2>&1 &
```

## Runtime proof of the Camel CLI path

The main Evolution process loaded:

```text
/usr/lib64/libcamel-1.2.so.68.0.0
/usr/lib64/libgpg-error.so.0.42.1
```

but not `libgpgme`.

A temporary wrapper placed in front of the Chameleon `gpg` executable then recorded the actual commands spawned by Evolution.

For signing, the captured invocation contained:

```text
--sign --detach --armor -u rfc9980-poc@example.invalid --output -
```

For public-key export, Camel invoked:

```text
--export
--export-options export-minimal,no-export-attributes
--export-filter ...
<rfc9980-poc@example.invalid>
```

This is direct runtime evidence for:

```text
Evolution
  -> Camel
  -> gpg-compatible CLI
  -> Chameleon
```

rather than a GPGME-based OpenPGP path.

## Configure the test account

Receiving can use a local Maildir:

```text
/home/chewbacca/Maildir
```

Create it if necessary:

```console
mkdir -p "$HOME/Maildir"/{cur,new,tmp}
```

Outgoing test transport:

```text
SMTP server: localhost
Port: 25
Authentication: none
Encryption: none
```

Identity:

```text
Name:  RFC9980 PoC
Email: rfc9980-poc@example.invalid
```

Keep Evolution's default option to use the sender e-mail address for OpenPGP key selection. With the `--userid "RFC9980 PoC <rfc9980-poc@example.invalid>"` certificate from the shared setup, no explicit fingerprint is required in the **OpenPGP Key ID** field.

## Create the three messages

Create:

```text
Unsigned
Signed only
Encrypted + signed
```

to:

```text
rfc9980-poc@example.invalid
```

Find Evolution's test messages in:

```text
~/.local/share/evolution/mail/local/.Outbox/cur
```

Confirm that the signed-only message uses:

```text
Content-Type: multipart/signed; micalg="pgp-sha512";
protocol="application/pgp-signature"
```

Confirm that the encrypted-and-signed message uses:

```text
Content-Type: multipart/encrypted;
protocol="application/pgp-encrypted"
```

## Independent verification

The signed-only message contained:

```text
:signature packet: algo 30
digest algo 10
```

Verify it independently and confirm:

```text
using MLDSA65_Ed25519 key ...
GOODSIG
VALIDSIG ... 30 ...
SIGNED_VERIFY_RC=0
```

The encrypted message contained:

```text
:pubkey enc packet: version 6, algo 35
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

Confirm that the decrypted MIME entity is also PGP/MIME signed:

```text
Content-Type: multipart/signed; micalg="pgp-sha512";
```

The inner signature contained:

```text
:signature packet: algo 30
```

Verify the inner signature independently and confirm:

```text
GOODSIG
VALIDSIG ... 30 ...
INNER_VERIFY_RC=0
```

One test message contained two identical algorithm-35 PKESK packets because Evolution's **Always encrypt to myself** option was enabled.

## Certificate identity interoperability

The shared setup uses a single explicit User ID:

```text
RFC9980 PoC <rfc9980-poc@example.invalid>
```

and leaves Evolution on its default sender-e-mail-address key selection. This combination worked without requiring an explicit fingerprint in the **OpenPGP Key ID** field.

A certificate generated with separate `--name` and `--email` options also worked cryptographically with Evolution, but one test displayed:

```text
Valid signature, but sender address and signer address do not match (RFC9980 PoC)
```

The certificate represented the identity as separate User IDs:

```text
RFC9980 PoC
<rfc9980-poc@example.invalid>
```

Independent verification still returned `GOODSIG`, `VALIDSIG` and exit status `0`; the warning was an identity-matching issue rather than a signature failure. Adding another Combined User ID during that investigation did not remove the warning.

Both certificate-generation approaches are therefore viable for the tested cryptographic operations. For this Evolution walkthrough, prefer the explicit `--userid` form containing the sender e-mail address because it gave the cleaner application-level result.

## Additional GnuPG-CLI compatibility observation

Camel also uses:

```text
--export-options export-minimal,no-export-attributes
```

A direct Chameleon 0.13.1 test rejected:

```text
no-export-attributes
```

as an unknown export option.

This is a separate GnuPG-CLI compatibility gap worth tracking independently of the successful signing and encryption path.

## Result

The procedure exercises this path:

```text
Evolution
  -> Camel OpenPGP
  -> GnuPG-compatible Chameleon CLI
  -> Sequoia OpenPGP / Keystore
```

using Fedora's stock GPGME package.

Independent verification confirms:

```text
Signing:
  ML-DSA-65+Ed25519
  OpenPGP algorithm 30
  GOODSIG / VALIDSIG

Encryption:
  ML-KEM-768+X25519
  version-6 PKESK
  OpenPGP algorithm 35
  DECRYPTION_OKAY

Inner signature:
  OpenPGP algorithm 30
  GOODSIG / VALIDSIG
```

The central architectural result is that Evolution does not require the experimental GPGME algorithm patch for this OpenPGP path.
