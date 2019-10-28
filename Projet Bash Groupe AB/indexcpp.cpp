#include <iostream>
#include <cstring>
#include <string>
#include <fstream>
#include <vector>

using namespace std;

struct Index {  //structure pour stocker les différents paramètres pour l'indexation
	string mot;
	int occurence;
	string num_ligne;
};


vector<string> mot_c(string ligne){  //fonction qui va créer des mots à partir des caractères
	unsigned int taille=ligne.length();
	char car;
	vector<string> mot_liste;
	string mot_f = ""; //initialisation du mot que l'on va fabriquer
	for (unsigned int i=0; i<=taille; i++){
		car= ligne[i];
		if ((car==' ')||(i==taille)){ //vu que notre fichier envoyé contient soit des lettres 
										//soit des ' ' on lui fait composer des mots à partir des lettres qui se suivent
			if ((mot_f=="a")||(mot_f=="à")||(mot_f=="y")||(mot_f.length()>1)){	 //On garde les lettres "a" à "y" qui peuvent être considérées comme des mots
				mot_liste.push_back(mot_f);		//On rentre le mot constitué dans une liste de mot
				mot_f="";	//reinitialisation de la variable ou on fabrique le mot
			}
			else {
				mot_f="";
			}
		}
		else {
			mot_f += car; //on ajoute le caractère pour créer le mot
		}
	}
	return mot_liste; //on retourne la liste de mots
}
		
			
		
int remplissage(string chemin, struct Index resultat[], const unsigned int MOT_MAX){
	
	unsigned int compt = 1; //compteur pour ligne
    ifstream fichier(chemin, ios::in);  // on ouvre le fichier en lecture
 
    if(fichier)  // si l'ouverture a réussi
        {   
			string ligne;
			while (getline(fichier, ligne)){ //tant qu'il y a une ligne dans un fichier
				vector<string> mots=mot_c(ligne);  //on envoie la ligne pour construire les mots et on récupère la liste de mots
				for (auto mot_c: mots){ //permet de sortir tous les mots de la variable qui contient la liste de mots
					for (unsigned int i=0; i<MOT_MAX; i++){
						if (resultat[i].mot == mot_c){	//Si le mot existe déjà
							resultat[i].occurence++;	//occurence +1
							resultat[i].num_ligne+="," + to_string(compt);	// on stocke sa ligne à la suite
							
							break;
						}
						if (resultat[i].mot == ""){  //si le mot n'existe pas on créé sa place dans le tableau
							resultat[i].mot = mot_c;  //on prend le mot
							resultat[i].occurence++; // on augmente son occurence
							resultat[i].num_ligne=to_string(compt); //et on ajoute la ligne
							break;
						}
					}	
				}
				compt++; //On augmente le compteur car on change de ligne
			}
			for(unsigned int i=0; i< MOT_MAX; i++){
				if (resultat[i].mot != ""){
				cout << resultat[i].mot << " " << resultat[i].occurence << " " << resultat[i].num_ligne << endl; //affichage du résultat qui va être envoyé au bash
				}
			}
			
			fichier.close(); //on ferme le fichier en ouverture
		}
    else{  // sinon
		cerr << "Impossible d'ouvrir le fichier !" << endl;
		return 1;
	}
 
    return 0;
}

int main(int argc, char* argv[]){
	
	const unsigned int MOT_MAX= stoi(argv[2]); //Prend la valeur du wc -w du bash, le nombre de mots est normalement exact donc il ne devrait pas y avoir de problème de core dump
	string chemin = argv[1];   //chemin prend le chemin du fichier

	struct Index *resultat=nullptr; //Création de pointeur pointant sur la struct
	resultat = new struct Index[MOT_MAX]; //On le définit en tableau
	
	for (unsigned int i=0; i< MOT_MAX; i++){ // On initialise le tableau pour être sur qu'il soit vide
		resultat[i].mot="";
		resultat[i].occurence=0;
		resultat[i].num_ligne="";
	}
	
	remplissage(chemin, resultat, MOT_MAX);
	
	delete[] resultat; // on libère la mémoire
	
	return 0;
} 
