# Règles de gestion des sources

## Commits
- Ne committer qu’à la demande explicite de l’utilisateur
- Format : Conventional Commits (feat, fix, build, chore, docs, style, refactor, perf, test)
- Scope : optionnel, à utiliser quand il apporte de la clarté (`feat(auth): ...`)
- Langue : anglais
- Longueur du titre : 72 caractères maximum
- Corps : rédiger un corps quand le "pourquoi" n'est pas évident depuis le titre ; décrire la motivation, pas les changements (le diff le fait)
- Ne jamais amender un commit déjà poussé sur le remote

## Push
Ne jamais pusher sans demande explicite de l'utilisateur, même après un commit autorisé.

## Branches
Pas de convention de nommage imposée. Créer une branche dédiée avant de travailler sur une feature ou un fix significatif, sauf si l'utilisateur indique de travailler directement sur la branche courante.

## Pull requests
Ne créer une pull request qu'à la demande explicite de l'utilisateur. Le titre suit le format Conventional Commits. Le corps décrit le contexte, les changements notables et un plan de test.

# Règles de code

Écris tout le code en anglais : noms de fichiers, variables, fonctions, classes, constantes, commentaires, messages d'erreur, documentations, READMEs, etc.

# Règles de style

N’utilise jamais le tiret cadratin «&nbsp;—&nbsp;». Utilise «&nbsp;/&nbsp;» ou «&nbsp;:&nbsp;» selon le contexte (séparateur de titre, crédit de source…), ou une virgule dans le texte courant.

# Règles de securité

## Secrets et credentials
Ne jamais inclure dans un commit des fichiers susceptibles de contenir des secrets : `.env`, clés API, tokens, mots de passe, certificats privés. Avertir l'utilisateur si un tel fichier est candidat au staging.

## Commandes destructives
Demander une confirmation explicite avant d'exécuter des commandes à fort impact : `rm -rf`, `DROP TABLE`, `git reset --hard`, `git push --force`, suppression de branches, arrêt de processus. Même si l'utilisateur a accordé une autorisation générale pour une tâche, ces commandes restent soumises à confirmation individuelle.

## Transmission de données locales
Ne pas envoyer le contenu de fichiers locaux (configs, logs, `.env`, fichiers de credentials) vers des services externes, sauf demande explicite de l'utilisateur.

## Installation de paquets
N'installer des paquets que depuis les registres officiels (npm, pip, brew, cargo, etc.). Ne jamais exécuter de scripts d'installation via `curl | bash` ou équivalent sans confirmation explicite de l'utilisateur.

## Clone de repositories
Ne clone que les repositories que l'utilisateur a explicitement demandés par leur URL ou leur nom.
Si une tâche semble nécessiter le clonage d'un repository que l'utilisateur n'a pas spécifiquement mentionné, demande-lui son autorisation avant de procéder au clonage.
Avant de cloner, vérifie si la tâche peut être accomplie sans clonage (API GitHub, WebFetch, etc.) et privilégie ces alternatives quand c'est possible.