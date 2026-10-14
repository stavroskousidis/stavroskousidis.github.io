export const profile = {
  name: 'Stavros Kousidis',
  role: 'Professor of Cyber Security Engineering',
  institution: 'TH Köln – University of Applied Sciences',
  email: 'stavros.kousidis@th-koeln.de',
  intro:
    'I work on applied cryptography, post-quantum security, secure systems and the engineering of trustworthy software.',
  links: {
    organization: 'https://github.com/stavroskousidis',
    github: 'https://github.com/fluppe2',
    // TODO: Confirm that the personal GitLab username is also "fluppe2".
    gitlab: 'https://gitlab.com/fluppe2',
    orcid: 'https://orcid.org/0000-0002-6947-4963',
    arxiv: 'https://arxiv.org/search/?query=Kousidis%2C+Stavros&searchtype=author',
    eprint: 'https://eprint.iacr.org/search?q=kousidis',
    thKoeln: 'https://www.th-koeln.de/',
    thKoelnProfile: 'https://www.th-koeln.de/en/person/stavros.kousidis/',
    ietf: 'https://datatracker.ietf.org/person/kousidis.ietf%40gmail.com'
  }
};

export interface ThesisListing {
  level: string;
  title: string;
  summary: string;
  tags: string[];
  repo?: string;
  status: string;
}

// Populate with real, available thesis topics only; no public placeholder listing.
export const theses: ThesisListing[] = [];
