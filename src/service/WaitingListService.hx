package service;
import tink.core.Error;
import db.UserAmap.Right;

class WaitingListService{


	public static function registerToWl(user:db.User,group:db.Amap,message:String){
		var t  = sugoi.i18n.Locale.texts;

		canRegister(user,group);

		var w = new db.WaitingList();
		w.user = user;
		w.group = group;
		w.message = message;
		w.insert();

		//emails
		var html = t._("<p><b>::name::</b> suscribed to the waiting list of <b>::group::</b> on ::date::</p>",{
			group:group.name,
			name:user.name,
			date:App.current.view.hDate(Date.now())
		});
		if(message!=null && message!=""){
			html += t._("<p>He/she left this message :<br/>\"::message::\"</p>",{message:message});
		}

		for( u in service.GroupService.getGroupMembersWithRights(group,[Right.GroupAdmin,Right.Membership]) ){

			App.quickMail(
				u.email,
				t._("[::group::] ::name:: suscribed to the waiting list.",{group:group.name,name:user.name}),
				html,
				group
			);
		}
	}

	public static function canRegister(user:db.User,group:db.Amap){
		var t  = sugoi.i18n.Locale.texts;
		
		if ( db.WaitingList.manager.select($amapId == group.id && $user == user) != null) {
			throw new Error(t._("You are already in the waiting list of this group"));
		}
		if ( db.UserAmap.manager.select($amapId == group.id && $user == user) != null) {
			throw new Error(t._("You are already member of this group."));
		}
	}

	/**
		the user cancels his request
	**/
	public static function removeFromWl(user:db.User,group:db.Amap){
		var t  = sugoi.i18n.Locale.texts;
		if ( user == null) {
			throw new Error(t._("You should be logged in."));
		}

		var wl = db.WaitingList.manager.select($amapId == group.id && $user == user,true);

		if ( wl == null) {
			throw new Error(t._("You are not in the waiting list of this group"));
		}
		wl.delete();
	}

	/**
		an admin cancels a request
	**/
	public static function cancelRequest(user:db.User,group:db.Amap){
		var t  = sugoi.i18n.Locale.texts;
		if ( user == null) throw "user is null";
		var wl = db.WaitingList.manager.select($amapId == group.id && $user == user,true);
		if ( wl == null) throw "this user is not in waiting list";

		//email the requester
		App.quickMail(
			wl.user.email,
			t._("[::group::] Membership request refused.",{group:group.name}),
			t._("Your membership request for <b>::group::</b> has been refused.",{group:group.name})
		);

		//email others admin
		for( u in service.GroupService.getGroupMembersWithRights(group,[Right.GroupAdmin,Right.Membership]) ){
			if(u.id==App.current.user.id) continue;
			App.quickMail(
				u.email,
				t._("[::group::] ::name:: membership request has been refused by ::admin::.",{group:group.name, name:user.name, admin:App.current.user.name}),
				t._("<p><b>::name::</b> was registred to the waiting list.</p><p><b>::admin::</b> has refused his/her request.</p>",{name:user.name, admin:App.current.user.name}),
				group
			);
		}
			
		wl.delete();
	}

	/**
		an admin approves a request
	**/
	public static function approveRequest(user:db.User,group:db.Amap){
		var t  = sugoi.i18n.Locale.texts;
		if ( user == null) throw "user is null";
		var wl = db.WaitingList.manager.select($amapId == group.id && $user == user,true);
		if ( wl == null) throw "this user is not in waiting list";

		if (db.UserAmap.get(user, group, false) == null){
			var ua = new db.UserAmap();
			ua.amap = wl.group;
			ua.user = wl.user;
			ua.insert();	
		}
		
		wl.delete();

		//email the requester
		App.quickMail(
			wl.user.email,
			t._("[::group::] Membership request accepted.",{group:group.name}),
			t._("<p>Your membership request for <b>::group::</b> has been accepted !</p><p>You're now a member of the group.</p>",{group:group.name}),
			group
		);

		//email others admin
		for( u in service.GroupService.getGroupMembersWithRights(group,[Right.GroupAdmin,Right.Membership]) ){
			if(u.id==App.current.user.id) continue;
			App.quickMail(
				u.email,
				t._("[::group::] ::name:: membership request has been accepted by ::admin::.",{group:group.name, name:user.name, admin:App.current.user.name}),
				t._("<p><b>::name::</b> was registred to the waiting list.</p><p><b>::admin::</b> has accepted his/her request.</p>",{name:user.name, admin:App.current.user.name}),
				group
			);
		}
			
		wl.delete();
	}



}