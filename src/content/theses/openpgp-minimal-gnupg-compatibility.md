---
title: "Deriving a Minimal GnuPG Compatibility Layer for OpenPGP Mail Clients"
summary: "Determine experimentally which GnuPG-compatible interfaces KMail, Claws Mail and Evolution require, and implement a minimal Sequoia-based compatibility environment."
researchQuestion: "Which GnuPG-compatible interfaces are actually required by KMail, Claws Mail and Evolution, and how small can a compatibility layer become while retaining complete OpenPGP functionality?"
level: "Bachelor"
status: "Open"
researchDirection: "Post-Quantum OpenPGP and Cryptographic Infrastructure"
published: "2026-10-18"
tags: ["OpenPGP", "Post-Quantum Cryptography", "Sequoia", "GPGME", "Compatibility"]
---

## Description

The current Fedora proof of concept shows three distinct integration paths: KMail and Claws Mail use GPGME, while Evolution uses Camel's GnuPG-compatible command-line integration. All three ultimately reach Sequoia Chameleon and Sequoia OpenPGP / Keystore. This compatibility approach enables RFC 9980 experiments without modifying every mail client, but it also preserves interfaces and runtime assumptions originally designed around GnuPG.

The goal of this thesis is not to reimplement GnuPG. You will derive experimentally the smallest compatibility contract needed by the three clients and investigate how much of that contract can be provided by a focused Sequoia-based implementation.

```text
              required interface
                     |
       +-------------+--------------+
       |             |              |
     KMail       Claws Mail      Evolution
       |             |              |
     GPGME          GPGME          CLI
       |             |              |
       +------ observed calls -------+
                     |
              minimal contract
```

## Scope and evaluation

Instrument the three clients in the existing Fedora test environment using process tracing, Chameleon logging or comparable mechanisms. Record the commands, options, status output, `gpgconf` lookups and error paths actually exercised during certificate listing and selection, signing, verification, encryption and decryption. Include the RFC 9980 algorithms ML-DSA-65+Ed25519 (30) and ML-KEM-768+X25519 (35).

From these observations, specify a minimal interface and implement a bounded prototype or shim covering the identified subset. Compare it with the current Chameleon setup using reproducible positive and negative tests. Clearly distinguish requirements observed for the selected clients from general GnuPG compatibility.

## Expected outcome

An empirical compatibility specification, a working prototype for the identified interface subset, and a reproducible evaluation showing which GnuPG-compatible components are necessary, optional or avoidable for the selected OpenPGP mail workflows.

## Starting points

- [Post-quantum OpenPGP on Fedora 45: shared setup](/notes/pq-openpgp-fedora-45-base/).
- [Sequoia Chameleon GnuPG](https://gitlab.com/sequoia-pgp/sequoia-chameleon-gnupg).
- [GPGME: Protocols and Engines](https://www.gnupg.org/documentation/manuals/gpgme/Protocols-and-Engines.html).
- [RFC 9980: Post-Quantum Cryptography in OpenPGP](https://www.rfc-editor.org/rfc/rfc9980).
