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

The Fedora proof of concept routes KMail and Claws Mail through GPGME, and Evolution through Camel's GnuPG-compatible command-line interface. All three reach Sequoia Chameleon, enabling RFC 9980 experiments but retaining interfaces originally designed around GnuPG.

The thesis seeks the smallest compatibility contract these clients actually require, without reimplementing GnuPG.

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

Instrument the three mail clients in the Fedora test environment. Trace commands, options, status output, `gpgconf` queries and error paths for certificate selection, signing, verification, encryption and decryption, including RFC 9980 algorithms 30 and 35.

Derive a minimal interface, implement a bounded shim, and compare it with Chameleon using reproducible positive and negative tests (e.g., missing certificates, invalid signatures, decryption errors). Distinguish client-specific needs from general GnuPG compatibility.

## Expected outcome

An empirical compatibility specification, a working prototype, and evidence of necessary, optional or avoidable interfaces. **Open-source publication of the developed code, tests, and reproducibility tools is mandatory**, under an agreed OSI-approved license. Modified Chameleon code must comply with its upstream license; independent shims require separate assessment. Agree before registration or choose another topic. See the [publication policy](/theses/publication-and-licensing/).

## Starting points

- [Post-quantum OpenPGP on Fedora 45: shared setup](/notes/pq-openpgp-fedora-45-base/).
- [Sequoia Chameleon GnuPG](https://gitlab.com/sequoia-pgp/sequoia-chameleon-gnupg).
- [GPGME: Protocols and Engines](https://www.gnupg.org/documentation/manuals/gpgme/Protocols-and-Engines.html).
- [RFC 9980: Post-Quantum Cryptography in OpenPGP](https://www.rfc-editor.org/rfc/rfc9980).
