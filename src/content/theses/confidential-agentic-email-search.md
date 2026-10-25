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

Semantic retrieval and AI agents can find discussions, reconstruct decisions, and summarize long email archives. But confidential correspondence creates a harder question: **where may decryption, indexing, retrieval, and reasoning occur without silently disclosing information?** This thesis studies **evidence-grounded retrieval** under explicit attacker models and trust boundaries, with KMail/Akonadi as an integration case study. An AI-generated answer is never a substitute for the original source messages.

## Scope and evaluation

Build a bounded, read-only prototype combining lexical search (e.g., BM25) and optional local embeddings, with results traceable to original messages and passages. Separate *index coverage*, *retrieval relevance*, and *answer faithfulness*. Reconstruct conversations where useful, and ensure generated answers expose sources, conflicts, and uncertainty.

Compare at least two deployment modes:

- **Local:** decryption, indexing, retrieval, and optional inference stay on the user's device.
- **On-premises:** organizational infrastructure processes selected data, becoming part of the explicitly trusted environment.
- **Remote agent:** an untrusted external agent issues limited queries through a local policy-enforcing broker; any returned metadata, excerpts, embeddings, or summaries constitute potential disclosure.

The trust-boundary analysis is central. **Private keys never leave the trusted cryptographic component. Decrypted bodies and attachments, derived embeddings, and summaries stay local by default.** They may cross a boundary only under a specific, authorized disclosure policy. Even metadata and opaque identifiers require leakage analysis. A remote agent cannot perform arbitrary semantic analysis on confidential plaintext while learning nothing about that plaintext.

Threat-model prompt injection in emails or attachments, excessive agent tool access, unauthorized retrieval, and inference from repeated queries. Evaluate retrieval quality (e.g., Recall@k, nDCG), citation support, unauthorized-disclosure attempts, latency, resource consumption, and scaling to larger archives. Synthetic or explicitly authorized test data are required. A complete KMail plugin or a new language model is not expected.

## Expected outcome

A documented threat and trust-boundary model, a policy-controlled retrieval prototype, and a comparative experimental study showing which functionality and security guarantees are achievable in each architecture. This thesis is independently feasible.

## Mandatory open-source publication

**This topic is available only to students who agree, before thesis registration, to publish all newly developed software, tests, and reproducibility tooling under an agreed [OSI-approved open-source license](https://opensource.org/licenses) by project completion.** The exact license is chosen with the supervisor in advance, subject to dependency compatibility; a KDE-compatible GPL license may suit client integration and AGPL may suit a separately licensed network service. Work may remain private during development. **No real confidential emails, keys, credentials, or protected datasets may be published.** If you cannot or do not wish to meet this requirement, **please choose another thesis topic**.

## Starting points

- [OpenPGP: RFC 9580](https://www.rfc-editor.org/rfc/rfc9580).
- [OWASP: RAG Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/RAG_Security_Cheat_Sheet.html).
- [KDE licensing policy](https://community.kde.org/Policies/Licensing_Policy).

## Related research

A complementary [Bachelor's thesis on trustworthy KMail search](/theses/trustworthy-kmail-search-completeness/) studies measurable index completeness and traceability. Neither thesis depends on the other's implementation.
