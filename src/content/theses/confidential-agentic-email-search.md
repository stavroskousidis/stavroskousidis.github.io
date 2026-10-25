---
title: "Confidential Agentic Email Search: Evidence and Trust Boundaries"
summary: "Evaluate hybrid and agentic search over sensitive, potentially OpenPGP-encrypted email, comparing local, on-premises, and remote architectures with explicit disclosure boundaries."
researchQuestion: "Which retrieval and agent operations can safely cross the trust boundary of an encrypted email archive, and how do deployment choices affect confidentiality, evidence quality, and search performance?"
level: "Master"
status: "Open"
researchDirection: "Trustworthy Information Retrieval and Email Security"
published: "2026-10-25"
tags: ["OpenPGP", "Agentic AI", "Hybrid Retrieval", "Trust Boundaries", "Privacy"]
---

## Description

AI agents can find discussions and reconstruct decisions across large archives, but **where may decryption, indexing, and reasoning occur without leaking confidential information?** This thesis investigates **evidence-grounded, read-only email retrieval** using KMail/Akonadi as an integration case study. Original messages, not generated answers, remain the evidence.

## Scope and evaluation

Prototype lexical and semantic **hybrid search**, with traceable source passages and optional answer synthesis. Distinguish **index coverage**, **retrieval relevance**, and **answer faithfulness**; report missing or conflicting evidence.

Compare at least two of these architectures:

- **Local:** decrypt, index, retrieve, and optionally infer on the user's device.
- **On-premises:** organizational infrastructure processes selected content, becoming an explicit part of the trusted environment.
- **Remote agent:** an external agent accesses a local policy-controlled search broker, receiving only authorized results.

**Encryption boundary:** Private keys remain in the trusted cryptographic component. Decrypted bodies and attachments, embeddings, keywords, and summaries stay local by default. Transferring any of them requires a specific authorization and leak analysis; even metadata and result identifiers can reveal information. A remote agent cannot freely analyze confidential plaintext while learning nothing about it.

Threat-model malicious email instructions (prompt injection), tool misuse, unauthorized queries, and repeated-query leakage. Evaluate retrieval (e.g., Recall@k, nDCG), evidence/citation accuracy, attempted disclosure, latency, and scalability using synthetic or authorized test data.

## Expected outcome

A threat model, enforced trust-boundary architecture, working prototype, and experimental comparison of useful search capabilities against achievable confidentiality guarantees. No new AI model or finished KMail plugin is required.

## Mandatory open-source publication

**To take this topic, students must agree before registration to publish all thesis-developed software, tests, and reproducibility tooling under a supervisor-agreed [OSI-approved open-source license](https://opensource.org/licenses).** Respect component dependencies: KDE-compatible GPL may suit the client; AGPL may suit a separately licensed network service. Work may remain private during development. Never publish confidential mail, keys, or credentials. **If you cannot or do not wish to publish your code as open source, choose another topic.**

## Starting points

- [RFC 9580: OpenPGP](https://www.rfc-editor.org/rfc/rfc9580).
- [OWASP RAG Security](https://cheatsheetseries.owasp.org/cheatsheets/RAG_Security_Cheat_Sheet.html).
- [KDE licensing policy](https://community.kde.org/Policies/Licensing_Policy).

## Related research

The [Bachelor's topic](/theses/trustworthy-kmail-search-completeness/) covers index completeness and integration; neither thesis depends on the other.
