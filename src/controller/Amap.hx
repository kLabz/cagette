package controller;
import db.UserContract;
import sugoi.form.Form;

class Amap extends Controller
{

	public function new() 
	{
		super();
	}
	
	@tpl("amap/default.mtt")
	function doDefault() {
		var contracts = db.Contract.getActiveContracts(app.user.amap, true, false);
		for ( c in Lambda.array(contracts).copy()) {
			if (c.endDate.getTime() < Date.now().getTime() ) contracts.remove(c);
		}
		view.contracts = contracts;
	}
	
	@tpl("form.mtt")
	function doEdit() {
		
		if (!app.user.isAmapManager()) throw t._("You don't have access to this section");
		
		var group = app.user.amap;
		
		var form = Form.fromSpod(group);

		//remove "shop mode" from flags
		var flags = form.getElement("flags");
		untyped flags.excluded = [1];
		//add a custom field for "shopmode"
		var data = [
			{label:t._("Shop Mode"),value:"shop"},
			{label:t._("CSA Mode"),value:"CSA"},
		];
		var selected = group.flags.has(db.Amap.AmapFlags.ShopMode) ? "shop" : "CSA";
		form.addElement( new sugoi.form.elements.RadioGroup("mode",t._("Ordering Mode"),data, selected), 8);
	
		if (form.checkToken()) {
			
			if(form.getValueOf("id") != app.user.amap.id) {
				var editedGroup = db.Amap.manager.get(form.getValueOf("id"),false);
				throw Error("/amap/edit",'Erreur, vous êtes en train de modifier "${editedGroup.name}" alors que vous êtes connecté à "${app.user.amap.name}"');
			}
			
			form.toSpod(group);

			if(form.getValueOf("mode")=="shop") group.flags.set(db.Amap.AmapFlags.ShopMode) else group.flags.unset(db.Amap.AmapFlags.ShopMode);
			
			if (group.extUrl != null){
				if ( group.extUrl.indexOf("http://") ==-1 &&  group.extUrl.indexOf("https://") ==-1 ){
					group.extUrl = "http://" + group.extUrl;
				}
			}
			
			group.update();
			throw Ok("/amapadmin", t._("The group has been updated."));
		}
		
		view.form = form;
	}
	
}