import db.User;
 
class App extends sugoi.BaseApp {

	public static var current : App = null;
	public static var t : sugoi.i18n.translator.ITranslator;
	public static var config = sugoi.BaseApp.config;
	
	public var eventDispatcher :hxevents.Dispatcher<event.Event>;	
	public var plugins : Array<plugin.IPlugIn>;
	
	public static function main() {
		
		App.t = sugoi.form.Form.translator = new sugoi.i18n.translator.TMap(getTranslationArray(), "fr");
		sugoi.BaseApp.main();
	}
	
	/**
	 * Init les plugins et le dispatcher juste avant de faire tourner l'app
	 */
	override public function mainLoop() {
		
		#if plugins
		//Gestion expérimentale de plugin. Si ça ne complile pas, commentez les lignes ci-dessous
		App.current.eventDispatcher = new hxevents.Dispatcher<event.Event>();
		App.current.plugins = [];
		App.current.plugins.push( new hosted.HostedPlugIn() );
		#end
	
		super.mainLoop();
	}
	
	public function getPlugin(name:String):plugin.IPlugIn {
		for (p in plugins) {
			if (p.getName() == name) return p;
		}
		return null;
	}
	
	public static function log(t:Dynamic) {
		if(App.config.DEBUG) {
			//neko.Web.logMessage(Std.string(t));
			Weblog.log(t);
		}
	}
	
	/**
	 * pour feeder l'object de traduction des formulaires
	 */
	public static function getTranslationArray() {
	
		var out = new Map<String,String>();
		out.set("firstName", "Prénom");
		out.set("lastName", "Nom");
		out.set("firstName2", "Prénom du conjoint");
		out.set("lastName2", "Nom du conjoint");
		out.set("email2", "e-mail du conjoint");
		out.set("address1", "adresse");
		out.set("address2", "adresse");
		out.set("zipCode", "code postal");
		out.set("city", "commune");
		out.set("phone", "téléphone");
		out.set("phone2", "téléphone du conjoint");
		out.set("select", "sélectionnez");
		out.set("contract", "Contrat");
		out.set("place", "Lieu");
		out.set("name", "Nom");
		out.set("cdate", "Date d'entrée dans l'Amap");
		out.set("quantity", "Quantité");
		out.set("paid", "Payé");
		out.set("user2", "(facultatif) partagé avec ");
		out.set("product", "Produit");
		out.set("user", "Adhérent");
		out.set("txtIntro", "Texte de présentation de l'Amap");
		out.set("txtHome", "Texte en page d'accueil pour les adhérents connectés");
		out.set("txtDistrib", "Texte à faire figurer sur les listes d'émargement lors des distributions");
		out.set("distributor1", "Distributeur 1");
		out.set("distributor2", "Distributeur 2");
		out.set("distributor3", "Distributeur 3");
		out.set("distributor4", "Distributeur 4");
		out.set("distributorNum", "Nbre de distributeurs nécéssaires (de 0 à 4)");
		out.set("startDate", "Date de début");
		out.set("endDate", "Date de fin");
		out.set("contact", "Reponsable");
		out.set("vendor", "Producteur");
		out.set("text", "Texte");
		out.set("flags", "Options");
		out.set("HasEmailNotif", "Recevoir des notifications par email 4h avant les distributions");
		out.set("HasMembership", "Gestion des adhésions");
		out.set("DayOfWeek", "Jour de la semaine");
		out.set("Monday", "Lundi");
		out.set("Tuesday", "Mardi");
		out.set("Wednesday", "Mercredi");
		out.set("Thursday", "Jeudi");
		out.set("Friday", "Vendredi");
		out.set("Saturday", "Samedi");
		out.set("Sunday", "Dimanche");
		out.set("cycleType", "Récurrence");
		out.set("Weekly", "hebdomadaire");
		out.set("Monthly", "mensuelle");
		out.set("BiWeekly", "toutes les deux semaines");
		out.set("TriWeekly", "toutes les 3 semaines");
		out.set("price", "prix");
		out.set("uname", "Nom");
		out.set("pname", "Produit");
		out.set("membershipRenewalDate", "Adhésions : Date de renouvellement");
		out.set("membershipPrice", "Adhésions : Coût de l'adhésion");
		out.set("UsersCanOrder", "Les adhérents peuvent saisir leur commande");
		out.set("OrdersManuallyEnabled", "Le contrat est actuellement ouvert aux commandes");
		out.set("contact", "Responsable");
		out.set("PercentageOnOrders", "Ajouter des frais au pourcentage de la commande");
		out.set("percentageValue", "Pourcentage des frais");
		out.set("percentageName", "Libellé pour ces frais");
		out.set("AmapAdmin", "Accès à la gestion d'Amap");
		out.set("Membership", "Accès à la gestion des adhérents");
		out.set("Messages", "Accès à la messagerie");
		return out;
	}
	
	
	public function populateAmapMembers() {		
		return user.amap.getMembersFormElementData();
	}
	
}