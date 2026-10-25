---
title: "Trustworthy Email Search: Verifiable Completeness and Evidence in KMail"
summary: "Build and evaluate a KMail/Akonadi search prototype that reveals indexing gaps, preserves links to original messages, and recovers reliably from synchronization failures."
researchQuestion: "How can a KMail search system make index coverage, result provenance, and synchronization correctness observable and verifiable at practical archive sizes?"
level: "Bachelor"
status: "Open"
researchDirection: "Trustworthy Information Retrieval and Email Security"
published: "2026-10-25"
tags: ["KMail", "Akonadi", "Information Retrieval", "Evidence Integrity", "Systems Engineering"]
---

## Description

Email search is trustworthy only if users can tell what was searched and where each result came from. A search may silently miss relevant messages because they were never downloaded, indexing failed, or the index has become stale. This thesis develops a bounded, read-only search prototype integrated with KMail's Akonadi infrastructure. The goal is **verifiable search**, not another AI chatbot.

## Scope and evaluation

Define a precise searchable corpus (for example, locally accessible messages in selected Akonadi collections at a synchronization checkpoint). Distinguish *index completeness* from *retrieval effectiveness*: even a complete index may fail to retrieve relevant messages.

Implement full-text search with a coverage report that distinguishes indexed, pending, unavailable, encrypted-but-not-indexed, failed, and stale items. Each result must identify its original message and, where possible, the matching passage. Investigate navigation from the results into KMail; a companion UI is acceptable if direct plugin integration proves impractical.

Maintain the index incrementally when messages arrive, change, move, or disappear. Evaluate consistency and recovery under controlled synchronization delays, deletions, and interruptions. Use reproducible test mailboxes with known expected results; measure coverage, query correctness, reference integrity, indexing throughput, latency, memory use, and index size as the archive grows.

Private keys and decrypted message bodies must not enter a persistent plaintext index by default. Clearly report content excluded for security reasons.

## Expected outcome

A documented integration architecture, a working search prototype, repeatable consistency tests, and an experimental evaluation of correctness, failure visibility, and scalability. Semantic search and LLMs are **not** required.

## Mandatory open-source publication

**This topic is available only to students who agree, before thesis registration, to publish all newly developed software, tests, and reproducibility tooling under an agreed [OSI-approved open-source license](https://opensource.org/licenses) by project completion.** The exact license is chosen with the supervisor in advance and must respect KDE and third-party license compatibility; a KDE-compatible GPL license is a likely choice for the client plugin. Development may use a private repository. **No credentials, private correspondence, cryptographic keys, or third-party confidential data may be published.** If you cannot or do not wish to meet the open-source requirement, **please choose another thesis topic**.

## Starting points

- [Akonadi framework and APIs](https://api.kde.org/).
- [SQLite FTS5](https://www.sqlite.org/fts5.html).
- [KDE licensing policy](https://community.kde.org/Policies/Licensing_Policy).

## Related research

A complementary [Master's thesis on confidential agentic email search](/theses/confidential-agentic-email-search/) investigates hybrid retrieval and disclosure boundaries. The topics are independently executable.
