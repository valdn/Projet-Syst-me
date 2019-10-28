#! /bin/bash

case $1 in

    --index)
		#prend le nombre de paramètre en entrée
        param=$# 
        #si le nombre de param est autre que 2 on envoie un help
        if [ $param -ne 2 ]
        then
            echo -e "\033[39;1m\n./IndexAndSearch <commande> <chemin>\n\033[m"
            exit
        fi
        #Pour vérifier les droits d'exécution sur le programme CPP
        if [ ! -x "indexcpp.exe" ] 
        then
			echo -e "\033[31;1m\nVous n'avez pas les droits d'exécution sur le programme \"indexcpp.exe\" veuillez les activer avec la commande \"chmod u+x indexcpp.exe\"\n\033[m" 
			exit
		fi
        #on prend le chemin qui a été entré
        chemin=$2 
        #création de la bdd si elle n'existe pas
        if [ -e $HOME/.indexation ]
        then 
            echo -e "\033[35;1m\nBase de données \"indexation\" est déjà existante\n\033[m"
        else
			echo -e "\033[35;1m\nCréation de la Base de données\n\033[m"
            mkdir $HOME/.indexation
        fi
        #création d'un temp qui va stocker des copies des fichiers à indexer
		mkdir $HOME/.indexation/temp 2>>/dev/null
		
		echo -e "\033[32;1mVeuillez patienter le script recherche les erreurs\n\033[m"
		#création des variables heures et dates utiles pour la création des logs
		heure=$(date +%H%M)
        jour=$(date +%Y%m%d)
        #création des fichiers qui vont permettrent la création du log
        #le log prendra la date actuelle et le temps actuel comme nom
        echo -e "Fichier log du $jour à $heure\n" > $HOME/.indexation/"$jour""$heure".log
        logs=$HOME/.indexation/"$jour""$heure".log
        #log temp d'erreur
        echo -e "\nErreurs :\n" > $HOME/.indexation/erreur.log
        erreur=$HOME/.indexation/erreur.log
        #log temp des fichiers indexés
        echo -e "\nIndexés :\n" > $HOME/.indexation/indexe.log
        indexe=$HOME/.indexation/indexe.log
        #log temp de fichiers déjà indexés
        echo -e "\nDéjà indexés :\n" > $HOME/.indexation/d_indexe.log
        d_indexe=$HOME/.indexation/d_indexe.log
        
        IFS=$'\n' #permet de prendre en compte les fichiers avec espace 
        
        #On prend le nombre de fichier sans les fichiers erreurs
		nb_fic=`find $chemin -type f -name "*.txt" 2>>$HOME/.indexation/error.txt | wc -l`
		#on stocke le type des erreurs
		ficherr=`file $HOME/.indexation/error.txt | sed -e 's/: /:/g' | cut -d':' -f2`	
		#variable qui va prendre tous les caractères spéciaux que l'on va supprimer par la suite pour faciliter l'indexation dans le c++
		variable=']_-()=@!?;./\"*%&[+°|1234567890¤$\t&£$¤<>' 
		#On initialise 2 compteurs (1 pour compter les fichiers erreurs, l'autre pour compter les fichiers indexés)
		cpt_e=0
		cpt=0
		#booleen d'erreur pour affichage d'information
		pres=true
		#permet d'afficher toutes les erreurs d'ouverture de fichier que l'on va stocker dans un log
		if [[ "$ficherr" != *"empty"* ]]
		then
			pres=false
			while read ligne
			do	
				err_fic=`echo $ligne | cut -d':' -f2`
				err_def=` echo $ligne | cut -d':' -f3`
				echo -e "Impossible d'accéder au fichier $err_fic car $err_def !" >> $erreur
			done < $HOME/.indexation/error.txt
		fi
		#on supprime le fichier d'erreur
		rm $HOME/.indexation/error.txt
		#On compte le nombre de fichier qui ne sont pas du bon type
		for fic in `find $chemin -type f -name "*.txt" 2>>/dev/null`
        do	
            nom=`basename $fic`
            type=`file $fic | sed -e 's/: /:/g' | cut -d: -f2`
            
            if [[ "$type" != *"ASCII text"* ]] && [[ "$type" != *"Unicode text"* ]] && [[ "$type" != *"ISO"* ]]
            then
				echo -e "Erreur : Le fichier $nom de type $type n'est pas de type ASCII ou UTF-8" >> $erreur
				((cpt_e++))
			fi
		done
		#On attend 2 secondes
		sleep 2
		#On compte le nombre de fichiers total potentiellement à indexer
		nb_fic=$(("$nb_fic"-"$cpt_e"))
		#Affiche si des erreurs ont été trouvées
        if [ "$cpt_e" = 0 ]  && $pres
		then
			echo -e "\033[31;1mAucune erreur\n\033[m"
		else 
			echo -e "\033[31;1mDes erreurs ont été trouvées, voir le log pour plus d'informations\n\033[m"
		fi
		#affichage d'information
		echo -e "\033[32;1mL'indexation va bientôt débuter !\n\033[m"		
		echo -e "\033[35;1mIl y a potentiellement $nb_fic fichiers à indexer\n\033[m"
		sleep 5
        #on recherche tous les fichiers .txt qui vont être stockés 1 à 1 dans la variable fic
        for fic in `find $chemin -type f -name "*.txt" 2>>/dev/null`
        do
			#On récupère le nom, md5, chemin, et le type
            nom=`basename $fic`
            dir=`dirname $fic`
            md5=`md5sum $fic | cut -d' ' -f1`
            type=`file $fic | sed -e 's/: /:/g' | cut -d: -f2`
            #booléen pour savoir si on indexe le fichier
            indexable=true
            #on restreint les types 
            if [[ "$type" == *"ASCII text"* ]] || [[ "$type" == *"Unicode text"* ]] || [[ "$type" == *"ISO"* ]]
            then       
				#on cherche parmis la BDD si le fichier existe déjà
				for index in `find $HOME/.indexation -type f -name "$nom*" 2>>/dev/null`
				do
					#on prend le nom, chemin et md5 des fichiers dans la BDD
					index_nom=`head -n 1 $index | cut -d':' -f1 ` 
					index_dir=`head -n 1 $index | cut -d':' -f3`
					index_md5=`head -n 1 $index | cut -d':' -f2`
					#On indexe pas les fichiers de la BDD
					if [ "$dir" = "$HOME/.indexation"* ]
					then
						indexable=false
						echo -e "\033[39;1mLe fichier \033[34;1m$nom\033[39;1m est un fichier de BDD il ne sera pas indexé\n\033[m"
						break
					fi
					#On indexe pas les fichiers de la corbeille (optionnel)
					if [ "$dir" = "$HOME/.local/share/Trash/files/temp" ]
					then
						indexable=false
						break
					fi
					#Si l'empreinte md5 change on réindexe le fichier
					if [ "$index_nom" = "$nom" ] && [ "$index_dir" = "$dir" ] && [ "$index_md5" != "$md5" ]
					then 
						#Affichage terminale
						echo -e "\033[39;1mL'empreinte md5 du fichier \033[33;1m$nom\033[39;1m a été changée, réindexation du fichier\n\033[m"
						#stockage pour le log
						echo -e "L'empreinte md5 du fichier $nom a été changée, réindexation du fichier" >> $indexe
						#On copie le fichier en transformant les majs en mins et les caractères spéciaux en espace
						cat $fic | sed -e 's/.*/\L&/' -e 's/['"${variable}"']/ /g' > $HOME/.indexation/temp/"$nom"
						#on compte le nombre de mots du nouveau fichier qui contient soit des caractères valides soit des espaces
						nbr_mot=`wc -w $HOME/.indexation/temp/"$nom"`
						#on créé l'entête pour le fichier indexation du fichier
						echo -e "$nom:$md5:$dir\n" > $HOME/.indexation/"$nom"
						#on envoie le fichier temporaire créé composé de lettres ou d'espaces et on envoie le nombre de mots pour avoir un tableau de mots parfait
						./indexcpp.exe $HOME/.indexation/temp/"$nom" $nbr_mot >> $HOME/.indexation/"$nom"
						#On incrémente le compteur pour montrer le nombre de fichiers indexé
						((cpt++))
						#puis on change le booléen pour pas qu'il soit reindexé
						indexable=false
						#et on quitte la boucle 
						break
					fi
					#si le fichier a la même empreinte, chemin et nom
					if [ "$index_nom" = "$nom" ] && [ "$index_dir" = "$dir" ] && [ "$index_md5" = "$md5" ]
					then
						#on indexe pas 
						echo -e "\033[39;1mLe fichier \033[34;1m$nom\033[39;1m est déjà indexé\n\033[m"
						#envoie au log
						echo -e "Le fichier $nom est déjà indexé" >> $d_indexe
						indexable=false
						break
					fi
				done 
				#si le booléen est vrai donc cela veut dire que le fichier n'existe pas dans la BDD
				if $indexable
				then
					echo -e "\033[39;1mLe fichier \033[32;1m$nom\033[39;1m n'existe pas dans la BDD, indexation du fichier\n \033[m"
					#envoie au log
					echo -e "Le fichier $nom n'existe pas dans la BDD, indexation du fichier" >> $indexe
					#On copie le fichier en enlevant les caracs spéciaux et en transformant les majs en mins
					cat $fic | sed -e 's/.*/\L&/' -e 's/['"${variable}"']/ /g' > $HOME/.indexation/temp/"$nom"
					#on compte le nombre de mots
					nbr_mot=`wc -w $HOME/.indexation/temp/"$nom"`
					#on créé le fichier indexation
					echo -e "$nom:$md5:$dir\n" > $HOME/.indexation/"$nom"
					#on envoie au cpp
					./indexcpp.exe $HOME/.indexation/temp/"$nom" $nbr_mot >> $HOME/.indexation/"$nom"
					#incrémentation compteur
					((cpt++))
				fi
			fi
		done
        #on supprime le dossier temp
        rm -R $HOME/.indexation/temp
        #Si le compteur est à 0 il n'y a alors pas eu d'indexation
        if [ "$cpt" = 0 ]
        then
			echo -e "\033[35;1mAucune indexation n'a été effectué\n\033[m"
        else if [ "$cpt" = 1 ]
			then
				echo -e "\033[35;1m$cpt fichier a été indexé\n\033[m"
			else
				echo -e "\033[35;1m$cpt fichiers ont été indexés\n\033[m"
			fi
        fi
        #On créé le fichier log
        cat $erreur $indexe $d_indexe >> $logs
        #On supprime les logs temporaire
        rm $erreur $indexe $d_indexe
        #on récupère le nom du log
        log_name=`basename $logs`
		#affichage du log créé
        echo -e  "\033[35;1mLe fichier $log_name a été créé dans le dossier $HOME/.indexation \n\033[m"
        #affichage d'information
        echo -e "\033[32;1mFin de l'indexation\n\033[m"
		
    ;;
    
    
        #fonction search
        --search)
        #nb param
        param=$#
        #affichage de commande help si le nb de param n'est pas bon
        if [ $param -ne 2 ]
        then
            echo -e "\033[39;1m\n./IndexAndSearch <commande> <mot>\n\033[m"
            exit
        fi
        #si la BDD n'existe pas on affiche et on quitte le script
        if [ ! -e $HOME/.indexation ]
        then 
            echo -e "\033[32;1m\nLe dossier de BDD n'existe pas\n\033[m"
            exit
        fi
        #booléen pour montrer si le mot existe ou pas dans la BDD
        trouver=true
        #transformation du mot en entrée en minuscule
        mot=`echo "$2" | tr [:upper:] [:lower:]`
        #compteur de résultat
        cpt=0
        ltr=""
        while [ "$ltr" != "t" ] && [ "$ltr" != "h" ]
        do
			echo -e "\033[32;1m\nRésultat sur terminal ou html ? (t/h)\033[m\n"
			#pour cacher la lettre entrée
			stty -echo
			read ltr
			stty echo
		done
		
		echo -e "\033[35;1mRecherche pour le mot \"$mot\"\033[m\n"
		#On prend les premières lignes du html que l'on copie dans notre fichier html final
		head -31 template.html | sed -e "s/.mot/$mot/g" > recherche.html
		#on attend 2 secondes
        sleep 2
        #parmis tous les fichiers dans la BDD  
        for fic in `find $HOME/.indexation -name "*.txt"`
        do
			#lit le fichier et récupère la ligne ou le mot existe
			ligne=`grep "^$mot " $fic`
			#si la ligne existe
			if [ -n "$ligne" ]
			then			
				#booleen faux pour dire qu'un résultat a été trouvé
				trouver=false
				#On prend l'occurence
				occurence=`echo "$ligne " | cut -d' ' -f2`
				#On récupère les lignes
				ligne=`echo "$ligne" | cut -d' ' -f3`
				#on récupère le nom
				nom=`head -n 1 $fic | cut -d':' -f1 `
				#on récupère le chemin
				chemin=`head -n 1 $fic | cut -d':' -f3`
				#Pour le résultat sur le terminal
				if [ "$ltr" = "t" ]
				then
					#affichage
					echo -e "\n\033[39;1m--------------------------\033[m"
					echo -e "\033[39;1m\nFichier : $nom $chemin"
					echo -e "Mot : $mot"
					echo -e "Occurence : $occurence"
					echo -e "Lignes : $ligne\033[m"
					#incrémentation du nombre de résultat
					((cpt++))
				#Pour le résultat sur HTML
				else
					#On répète la zone qui affiche les résulats par le nombre de résultats
					head -37 template.html | tail +32 | sed "s/.nom/$nom/g; s:.chemin:$chemin:g; s/.occurence/$occurence/g; s/.ligne/$ligne/g" >> recherche.html
				fi
			fi
		done
		#si le booléen est vrai alors le mot n'existe pas dans la BDD
		if $trouver
		then
			echo -e "\033[32;1mLe mot \"$mot\" n'existe pas dans la Base de Données\n\033[m"
		exit
		fi
		#Terminal
		if [ "$ltr" = "t" ]
		then
			echo -e "\n\033[39;1m--------------------------\033[m"
			#Affichage du nombre de résultat
			if [ "$cpt" = 1 ]
			then
					echo -e "\033[35;1m\n$cpt résultat a été trouvé\033[m"
			else
					echo -e "\033[35;1m\n$cpt résultats ont été trouvés\033[m"
			fi
			echo -e ""
		#HMTL
		else
			#On copie les dernières lignes du HTML dans notre fichier HTML final
			tail +38 template.html >> recherche.html
			#On ouvre le navigateur internet par défaut avec le fichier HTML final
			xdg-open recherche.html 2>>/dev/null
			echo -e "\033[32;1mLa page HTML a été ouverte\033[m\n"
		fi
    ;;
    
    
		#fonction clean
		--clean)
		#nb param
        letter=""
        #si le dossier de BDD existe
		if [ -e $HOME/.indexation ]
		then 
			#si la lettre n'est pas o ou n
			while [ "$letter" != "o" ] && [ "$letter" != "O" ] && [ "$letter" != "n" ] && [ "$letter" != "N" ]
			do
				echo -e "\033[32;1m\nEffacer la base de données d'indexation ? o/n\033[m"
				#Permet de cacher le mot entré
				stty -echo
				read letter
				stty echo
			done
			#on supprime si c'est o
			if [ "$letter" = "o" ] || [ "$letter" = "O" ]
			then
				rm -R $HOME/.indexation
				echo -e "\033[32;1m\nLa base de données d'indexation a été supprimée\n\033[m"
			#sinon on ne supprime pas
			else
				echo -e "\033[32;1m\nLa base de données n'a pas été supprimée\n\033[m"
			fi
		#sinon on montre que la BDD n'existe pas
		else 
			echo -e "\033[32;1m\nLa base de données d'indexation n'existe pas\n\033[m"
		fi
    ;;
		#help
		*)
		echo -e "\033[39;1m\nLa commande n'existe pas voir le README.txt pour plus d'informations\n\033[m"
		
		exit
	;;
esac
