package db;
import sys.db.Types;

enum OperationType{
	VOrder; //order on a varying order contract
	COrder;//order on a constant order contract
	Payment;
	Membership;	
}

typedef PaymentInfos = {type:String, ?remoteOpId:Int, ?netAmount:Float}; 
typedef VOrderInfos = {basketId:Int};
typedef COrderInfos = {contractId:Int};


/**
 * Payment operation 
 * 
 * @author fbarbut
 */
class Operation extends sys.db.Object
{
	public var id : SId;
	public var name : SString<128>;
	public var amount : SFloat;
	public var date : SDateTime;
	public var type : SEnum<OperationType>;
	public var data : SData<Dynamic>;
	@hideInForms @:relation(relationId) public var relation : SNull<db.Operation>; //linked to another operation : ie a payment pays an order
	
	@:relation(userId) public var user : db.User;
	@hideInForms @:relation(groupId) public var group : db.Amap;
		
	public var pending : SBool; //a pending payment means the payment has not been confirmed, a pending order means the ordre can still change before closing.
	
	public function getTypeIndex(){
		var e : OperationType = type;		
		return e.getIndex();
	}
	
	/**
	 * if operation is a payment, give the payment type
	 */
	public function getPaymentType():String{
		switch(type){
			case Payment: 
				var x : PaymentInfos = this.data;
				if (data == null){
					return null;
				}else{
					return x.type;
				}				
			default : return null;
		}		
	}	
	
	/**
	 * get payments linked to this order transaction
	 */
	public function getRelatedPayments(){
		return db.Operation.manager.search($relation == this, false);
	}
	
	public function getOrderInfos(){
		return switch(type){
			case COrder, VOrder : this.data;				
			default : null;
		}
	}
	
	public function getPaymentInfos():PaymentInfos{
		return switch(type){
			case Payment : this.data;
			default : null;
		}
	}
	
	public static function getOperations(user:db.User,group:db.Amap){		
		return manager.search($user == user && $group == group,{orderBy:date},false);		
	}
	
	public static function getOrderOperations(user:db.User, group:db.Amap,?limit=50 ){		
		//return manager.search($user == user && $group == group && $type!=Payment,{orderBy:date},false);		
		//return manager.search($user == user && $group == group && $relation==null,{orderBy:date},false);		
		return manager.search($user == user && $group == group,{orderBy:date,limit:limit},false);		
	}
	
	public static function getLastOperations(user:db.User, group:db.Amap, ?limit = 50){
		
		var c = manager.count($user == user && $group == group);
		c -= limit;
		if (c < 0) c = 0;
		return manager.search($user == user && $group == group,{orderBy:date,limit:[c,limit]},false);	
	}
	
	/**
	 * Create a new transaction
	 * @param	orders
	 */
	public static function makeOrderOperation(orders: Array<db.UserContract>, ?basket:db.Basket){
		
		if (orders == null) throw "orders are null";
		if (orders.length == 0) throw "no orders";
		if (orders[0].user == null ) throw "no user in order";
		
		var _amount = 0.0;
		for ( o in orders ){
			var t = o.quantity * o.productPrice;
			_amount += t + t * (o.feesRate / 100);
		}
		
		var contract = orders[0].product.contract;
		
		var t = new db.Operation();
		var user = orders[0].user;
		var group = orders[0].product.contract.amap;
		
		if (contract.type == db.Contract.TYPE_CONSTORDERS){
			//Constant orders			
			var dNum = contract.getDistribs(false).length;
			t.name = "" + contract.name + " (" + contract.vendor.name+") "+ dNum+" distributions";			
			t.amount = dNum * (0 - _amount);
			t.date = Date.now();
			t.type = COrder;
			var data : COrderInfos = {contractId:contract.id};
			t.data = data;			
			t.user = user;
			t.group = group;
			t.pending = true;					
			
		}else{
			
			if (basket == null) throw "varying contract orders should have a basket";
			
			//varying orders
			t.name = "Commande pour le " + App.current.view.dDate(orders[0].distribution.date);
			t.amount = 0 - _amount;
			t.date = Date.now();
			t.type = VOrder;
			var data : VOrderInfos = {basketId:basket.id};
			t.data = data;
			t.user = user;			
			t.group = group;
			t.pending = true;		
		}
		
		t.insert();
		
		updateUserBalance(t.user, t.group);
		
		return t;	
	}
	
	
	public static function updateOrderOperation(t:db.Operation, orders: Array<db.UserContract>, ?basket:db.Basket){
		
		t.lock();
		
		var _amount = 0.0;
		for ( o in orders ){
			var t = o.quantity * o.productPrice;
			_amount += t + t * (o.feesRate / 100);
		}
		
		var contract = orders[0].product.contract;
		if (contract.type == db.Contract.TYPE_CONSTORDERS){
			//Constant orders			
			var dNum = contract.getDistribs(false).length;
			t.name = "" + contract.name + " (" + contract.vendor.name+") "+ dNum+" distributions";			
			t.amount = dNum * (0 - _amount);
			t.date = Date.now();			
			
		}else{
			
			if (basket == null) throw "varying contract orders should have a basket";
			
			t.amount = 0 - _amount;
			t.date = Date.now();			
		}
		
		
		t.update();
		
		updateUserBalance(t.user, t.group);
		
		return t;
	}
	
	/**
	 * Record a new payment operation
	 * @param	type
	 * @param	amount
	 * @param	name
	 * @param	relation
	 */
	public static function makePaymentOperation(user:db.User,group:db.Amap,type:String, amount:Float, name:String, ?relation:db.Operation ){
		
		var t = new db.Operation();
		t.amount = Math.abs(amount);
		t.date = Date.now();
		t.name = name;
		t.group = group;
		t.pending = true;
		t.user = user;
		t.type = Payment;
		var data : PaymentInfos = {type:type};
		t.data = data;
		if(relation!=null) t.relation = relation;
		t.insert();
		
		updateUserBalance(user, group);
		
		return t;
		
	}
	
	/**
	 * update user balance
	 */
	public static function updateUserBalance(user:db.User,group:db.Amap){
		
		var ua = db.UserAmap.getOrCreate(user, group);
		var b = sys.db.Manager.cnx.request('SELECT SUM(amount) FROM Operation WHERE userId=${user.id} and groupId=${group.id} and !(type=2 and pending=1)').getFloatResult(0);
		b = Math.round(b * 100) / 100;
		ua.balance = b;
		ua.update();
	}
	
	/**
	 * when updating a (varying) order , we need to update the existing pending transaction
	 */
	public static function findVOrderTransactionFor(dkey:String, user:db.User, group:db.Amap,?onlyPending=true):db.Operation{
		
		var date = dkey.split("|")[0];
		var placeId = Std.parseInt(dkey.split("|")[1]);
		var transactions  = new List();
		if (onlyPending){
			transactions = manager.search($user == user && $group == group && $pending == true && $type==VOrder , {orderBy:date}, true);
		}else{
			transactions = manager.search($user == user && $group == group && $type==VOrder , {orderBy:date}, true);
		}
		
		var basket = db.Basket.get(user, db.Place.manager.get(placeId,false), Date.fromString(date));
		
		for ( t in transactions){
			
			switch(t.type){
				
				case VOrder :
					var data : VOrderInfos = t.data;
					if ( data == null) continue;
					if (data.basketId == basket.id) return t;
					
					
				default : 
					continue;				
			}
		}
		
		return null;
	}
	
	/**
	 * when updating a constant order, we need to update the existing transaction.
	 * 
	 */
	public static function findCOrderTransactionFor(contract:db.Contract, user:db.User){
		
		if (contract.type != db.Contract.TYPE_CONSTORDERS) throw "contract type should be TYPE_CONSTORDERS";
		
		var transactions = manager.search($user == user && $group == contract.amap && $amount<0 && $type==COrder, {orderBy:date,limit:100}, true);
		
		for ( t in transactions){
			
			switch(t.type){
				
				case COrder :
					
					//var id = Lambda.find(orders, function(x) return db.UserContract.manager.get(x, false) != null);					
					//if (id == null) {						
						////all orders in this transaction dont exists anymore
						//t.delete();
						//continue;
					//}else{
						//for ( i in orders){
							//var order = db.UserContract.manager.get(i);
							//if (order == null) continue;
							//if (order.product.contract.id == contract.id) return t;
						//}	
					//}
					var data : COrderInfos = t.data;
					if (data == null) continue;
					if (data.contractId == contract.id) return t;
					
					
				default : 
					continue;				
			}
		}
		
		return null;
		
	}
	
	public static function getPaymentTypes(group:db.Amap):Array<payment.Payment>{
		var out :Array<payment.Payment> = [];
		
		//populate with activated payment types.
		var all = payment.Payment.getPaymentTypes();
		if ( group.allowedPaymentsType == null ) return [];
		for ( t in group.allowedPaymentsType){
			
			var found = Lambda.find(all, function(a) return a.type == t);
			if (found != null) out.push(found);
		}
		return out;
	}
	
	/**
	 * create the needed order operations
	 * @param	orders
	 */
	public static function onOrderConfirm(orders:Array<db.UserContract>):Array<db.Operation>{
		
		if (orders.length == 0) return null;
		var out = [];
		var user = orders[0].user;
		var group = orders[0].product.contract.amap;
		
		//should not go further if group has not activated payements
		if (user==null || !group.hasPayments()) return null;
		
		//we consider that ALL orders are from the same contract type : varying or constant
		if (orders[0].product.contract.type == db.Contract.TYPE_VARORDER ){
			
			// varying contract :
			//manage separatly orders which occur at different dates
			var ordersGroup = tools.ObjectListTool.groupOrdersByKey(orders);
			
			for ( orders in ordersGroup){
				
				//find basket
				var basket = null;
				for ( o in orders) {
					if (o.basket != null) {
						basket = o.basket;
						break;
					}
				}
				
				//get all orders for the same place & date, in order to update related transaction.
				var k = orders[0].distribution.getKey();
				var allOrders = db.UserContract.getUserOrdersByMultiDistrib(k, user, group);	
				
				//existing transaction
				var existing = db.Operation.findVOrderTransactionFor( k , user, group);
				if (existing != null){
					out.push( db.Operation.updateOrderOperation(existing,allOrders,basket) );	
				}else{
					out.push( db.Operation.makeOrderOperation(allOrders,basket) );			
				}
				
			}
			
		}else{
			
			// constant contract
			// create/update a transaction computed like $distribNumber * $price.
			var contract = orders[0].product.contract;
			
			var existing = db.Operation.findCOrderTransactionFor( contract , user);
			if (existing != null){
				out.push( db.Operation.updateOrderOperation(existing, contract.getUserOrders(user) ) );
			}else{
				out.push( db.Operation.makeOrderOperation( contract.getUserOrders(user) ) );
			}
			
			
		}
		
		return out;
		
	}
	
	
}