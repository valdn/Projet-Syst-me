# Projet-Systeme
Réalisation d’une application, en Bash et C++, d’indexation de fichier texte et de recherche de mot.

Projet BASH

Groupe AB: Valentin DI NARDO, Florian CASSAGNE, Elliott EVAN

Pour indexer des fichiers utiliser la commande "IndexAndSearch.bash --index <chemin>"

Cette commande permet d'indexer tous les fichiers compris dans le dossier et sous-dossier dans le chemin, vos fichiers seront indexés dans la BDD "$HOME/.indexation. Tous les mots auront leurs occurences et leurs lignes d'apparitions écrits dans le fichier et le nom, le chemin et l'empreinte md5 du fichier à indexer se trouvera en première ligne du fichier d'indexation.

Pour rechercher un mot utiliser la commande "IndexAndSearch.bash --search <mot>"

Cette commande permet de rechercher un mot dans la BDD, cette commande affichera (si le mot existe dans la BDD) le nom, le chemin du fichier où se trouve le mot et le nombre d'occurences et les lignes d'apparitions du mot en question. Vous avez la possibilité d'afficher ce résultat sur le terminal ou sur une page HTML.

Pour supprimer la BDD utiliser la commande "IndexAndSearch --clean"

Cette commmande permet de supprimer la BDD, si elle existe.

A savoir:

-Un fichier .log est créé à chaque indexation, il permet de savoir ce qu'il s'est passé lors de l'indexation, en 3 parties : 1 = Les erreurs, 2 = Les fichiers indexés, 3 = Les fichiers déjà indexés.

-Pensez à donner les droits d'exécution sur le script et sur l'exécutable c++ avec la commande
"chmod u+x <fichier>".
