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

The Fedora proof of concept exposes three integration paths: KMail and Claws Mail use GPGME, while Evolution uses Camel's GnuPG-compatible command-line integration. All three ultimately reach Sequoia Chameleon. This enables RFC 9980 experiments without modifying every mail client, but retains interfaces originally designed around GnuPG.

The thesis asks how much of that compatibility surface is actually required. The goal is not to reimplement GnuPG, but to derive and test the smallest contract needed by the selected clients.

```text
              required interface
                     |
       +-------------+--------------+
       |             |              |
     KMail       Claws Mail      Evolution
       |             |              |
     GPGME          GPGME          CLI
       |             |              |
       +------ observed calls ------+
                     |
              minimal contract
```

## Scope and evaluation

Instrument KMail, Claws Mail and Evolution in the existing Fedora test environment. Trace the commands, options, status output, `gpgconf` lookups and error paths exercised during certificate selection, signing, verification, encryption and decryption, including RFC 9980 algorithms 30 and 35.

From the observations, specify a minimal interface and implement a bounded prototype or shim for the identified subset. Compare it with the current Chameleon setup using reproducible positive and negative tests, for example missing certificates, invalid signatures and decryption failures. Clearly distinguish requirements observed for these clients from general GnuPG compatibility.

## Expected outcome

An empirical compatibility specification, a working prototype for the identified subset, and evidence showing which GnuPG-compatible interfaces are necessary, optional or avoidable for the selected OpenPGP mail workflows.

## Starting points

- [Post-quantum OpenPGP on Fedora 45: shared setup](/notes/pq-openpgp-fedora-45-base/).
- [Sequoia Chameleon GnuPG](https://gitlab.com/sequoia-pgp/sequoia-chameleon-gnupg).
- [GPGME: Protocols and Engines](https://www.gnupg.org/documentation/manuals/gpgme/Protocols-and-Engines.html).
- [RFC 9980: Post-Quantum Cryptography in OpenPGP](https://www.rfc-editor.org/rfc/rfc9980).
