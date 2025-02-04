extends Spatial
class_name Joueur

var id: int
var estLocal: bool = false

var plateau
var main: Array
var carteVotee: Carte
var points: int = 0

onready var mainRoot = $CameraPos/MainRoot

onready var cameraPos: Spatial = $CameraPos

onready var CAM_MID = get_node("/root/Partie/Scene/Camera")
const NODE_CAM = preload("res://Scenes/Joueur/CameraJoueur.tscn")
const NODE_UI = preload("res://Scenes/Joueur/UiJoueur.tscn")
const NODE_UI_CONTEUR = preload("res://Scenes/Joueur/UiConteur.tscn")
const NODE_CHAT = preload("res://Scenes/Chat/Chat.tscn")
const NODE_UI_TOURDEPARTIE = preload("res://Scenes/Joueur/UiTourDePartie.tscn")
const NODE_UI_DISPLAY = preload("res://Scenes/Joueur/UiBoutonsDisplay.tscn")

const NODE_CARTE = preload("res://Scenes/Carte/Carte.tscn")
var estConteur: bool = false 
var ui 
var uiConteur
var uiChat: Chat
var uiTourDePartie
var myCam
var uiDisplay


var etat: int

func _ready():
	Network.connect("ChangementConteur", self, "setConteur")
	Network.connect("updateTheme",self,"changeTheme")
	Network.connect("APoseCarte",self,"carteSelectectionnee")
	Network.connect("vote",self,"peuxVoter")
	Network.connect("voirRes",self,"voirRes")
	Network.connect("carteVotee", self, "aVote")
	Network.connect("reVote", self, "peutReVoter")


func init(idJoueur: int, plateauDePartie, couleurJoueur):
	self.id = idJoueur
	self.estLocal = estLocal()
	self.plateau = plateauDePartie
	self.main = []
	self.estConteur = false
	self.etat = Globals.EtatJoueur.ATTENTE_CHOIX_THEME
	self.myCam = null

	var tete = $MeshRoot/Head
	var corps = $MeshRoot/Body
	var chapeau = $MeshRoot/MeshInstance3
	var chapeau2 = $MeshRoot/MeshInstance4
	
	var material = SpatialMaterial.new()
	material.set_albedo(couleurJoueur)

	if !estLocal():
		corps.set_material_override(material)
		tete.set_material_override(material)
		chapeau.set_material_override(material)
		chapeau2.set_material_override(material)

	if estLocal():
		var cam: Camera = NODE_CAM.instance()
		cameraPos.add_child(cam)
		cam.set_current(true)
		# UI dans le joueur car c'est celui qui est en local qui en a besoin
		self.uiConteur = NODE_UI_CONTEUR.instance()
		self.add_child(uiConteur)
		self.ui = NODE_UI.instance()
		self.add_child(ui)
		self.uiChat = NODE_CHAT.instance()
		self.add_child(uiChat)
		self.uiDisplay = NODE_UI_DISPLAY.instance()
		self.add_child(uiDisplay)
		
		self.uiTourDePartie = NODE_UI_TOURDEPARTIE.instance() 
		self.uiTourDePartie.connect("pretNextRound", self, "pretPasserTour")
		self.add_child(uiTourDePartie) 
		
		self.myCam = cam

		corps.set_material_override(material)
		tete.set_material_override(material)
		chapeau.set_material_override(material)
		chapeau2.set_material_override(material)
		
		self.uiTourDePartie.enlever()
		self.uiConteur.attendreChoixConteur()

func _input(event):
	# Pour changer de cam lorsque l'on utilise les fleches
	if event is InputEventKey:
		if self.estLocal():
			if event.pressed and event.scancode == KEY_UP:
				if(self.myCam.current == true):
					self.myCam.current = false
					CAM_MID.current = true
			if event.pressed and event.scancode == KEY_DOWN:
				if(self.CAM_MID.current == true):
					CAM_MID.current = false
					self.myCam.current = true

func _process(delta):
	if(self.id == Network.id):
		for carte in self.main:
			carte.afficheEffets()

func piocheCarte(nomCarte: String, type: int):
	var instanceCarte = NODE_CARTE.instance()
	mainRoot.add_child(instanceCarte)
	instanceCarte.init(nomCarte, estLocal(), estLocal())
	main += [instanceCarte]
	
	instanceCarte.positionCible = Vector3(-0.6+0.5*(main.size()-1), 0, 0)
	
	if estLocal:
		instanceCarte.connect("carteCliquee", self, "localPoseCarte")
	
	instanceCarte.type = type
	instanceCarte.estDansMain = true
	instanceCarte.estSurPlateau =  false


func localPoseCarte(carte):
	
	if(!self.estConteur):
		self.uiConteur.attendreSelections()
		self.etat = Globals.EtatJoueur.ATTENTE_SELECTIONS
	else:
		self.uiConteur.afficheUiConteur(carte.nom)
		self.etat= Globals.EtatJoueur.CHOIX_THEME
		
	Network.posercarte(self.id, carte.nom)
	carte.disconnect("carteCliquee", self, "localPoseCarte")
	carte.peutEtreHover = false
	Network.verifEtat(Globals.EtatJoueur.ATTENTE_SELECTIONS)


#================
#	getters et trucs utiles toi même tu sais

func getCarte(nom: String):
	for c in self.main:
		if c.nom == nom:
			return c
	return null


func estLocal()-> bool:
	""" Renvoie si le joueur est local (aka le joueur que les client est) """
	return self.id == Network.id

func getId():
	return self.id

func retireCarte(carte: Carte):
	if carte in self.main:
		self.main.erase(carte)
		self.mainRoot.remove_child(carte)
		

# ===========
# UI
func setConteur(idJoueur):
	self.estConteur = self.id == idJoueur
	if(self.estConteur):
		self.etat = Globals.EtatJoueur.SELECTION_CARTE_THEME
		if(self.estLocal()):
			self.uiConteur.enlever()
	else:
		if(self.estLocal()):
				self.uiConteur.attendreChoixConteur()
		self.etat = Globals.EtatJoueur.ATTENTE_CHOIX_THEME
		
func changeTheme(theme, nomConteur):
	if(self.estConteur):
		self.etat = Globals.EtatJoueur.ATTENTE_SELECTIONS
	else:
		self.etat = Globals.EtatJoueur.SELECTION_CARTE
	if estLocal():
		if(self.estConteur):
			self.ui.changeTheme(theme)
			self.uiConteur.attendreSelections()
		else:
			self.ui.changeTheme(theme, false, nomConteur)
			self.uiConteur.enlever()

func carteSelectectionnee(idJoueur):
	# Si le joueur a bien posé la carte et qu'il est local
	if(self.id == idJoueur):
		# Alors si il est conteur
		if(self.estConteur):
			# On lui demande le choix du theme
			self.etat = Globals.EtatJoueur.CHOIX_THEME
		else:
			# Sinon il attends le conteur
			self.etat = Globals.EtatJoueur.ATTENTE_SELECTIONS
		Network.verifEtat(Globals.EtatJoueur.ATTENTE_SELECTIONS)

func peuxVoter():
	if(self.estConteur):
		self.etat = Globals.EtatJoueur.ATTENTE_VOTES
		if(estLocal()):
			self.uiConteur.attendreVotes()
	else:
		
		
		self.etat = Globals.EtatJoueur.VOTE
		if(estLocal()):
			self.uiConteur.enlever()
	if(estLocal()):
		self.myCam.current = false
		CAM_MID.current = true
		Network.verifEtat(Globals.EtatJoueur.ATTENTE_VOTES)
	
func peutReVoter(idJoueur):
	if self.id==idJoueur:
		if(self.estConteur):
			self.etat = Globals.EtatJoueur.ATTENTE_VOTES
			if(estLocal()):
				self.uiConteur.attendreVotes()
		else:
			
			
			self.etat = Globals.EtatJoueur.VOTE
			if(estLocal()):
				self.uiConteur.enlever()
		if(estLocal()):
			self.myCam.current = false
			CAM_MID.current = true
			Network.verifEtat(Globals.EtatJoueur.ATTENTE_VOTES)

func aVote(nomCarte, idJoueur):
	if(idJoueur == self.id):
		self.carteVotee = nomCarte
		self.etat = Globals.EtatJoueur.ATTENTE_VOTES
		if(self.estLocal()):
			self.uiConteur.attendreVotes()
			Network.verifEtat(Globals.EtatJoueur.ATTENTE_VOTES)
	
func voirRes():
	self.etat = Globals.EtatJoueur.VOIR_RESULTAT
	if(estLocal()):
		self.uiConteur.enlever()
		self.uiTourDePartie.afficher()
	# Attribution des points

func pretPasserTour():
	self.etat = Globals.EtatJoueur.ATTENTE_PROCHAINE_MANCHE
	Network.pretPourTour()
	
func nouvelleManche():
	if(estLocal()):
		self.uiTourDePartie.enlever()
		self.uiTourDePartie.resetNbPrets()
		self.myCam.current = true
		CAM_MID.current = false
		self.ui.resetTheme()
		self.uiConteur.attendreChoixConteur()
	while(self.main.size() < 5):
		pass
	for carte in self.main:
		carte.positionCible = Vector3.ZERO
	for i in range(0,self.main.size()):
		var carte = self.main[i]
		carte.positionCible = Vector3(-0.6+0.5*(i), 0, 0)
