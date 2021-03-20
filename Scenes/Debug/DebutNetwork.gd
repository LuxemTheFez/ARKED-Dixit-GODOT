extends Node

onready var labelId = $UI/LabelId
onready var labelUtilisateurs = $UI/labelUtilisateurs


func _process(_delta):
	labelId.text = "ID : " + str(Network.id)
	
	var utilisateursText = "Utilisateur(s) :\n"
	for usId in Network.utilisateurs:
		utilisateursText += "\t" + "id: " + str(usId) + "\t"
		if "estPret" in Network.utilisateurs[usId]:
			utilisateursText += "estPret: " + str(Network.utilisateurs[usId].estPret) + "\n"
	labelUtilisateurs.text = utilisateursText
