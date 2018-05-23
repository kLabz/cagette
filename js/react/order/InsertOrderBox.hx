package react.order;
import react.ReactDOM;
import react.ReactComponent;
import react.ReactMacro.jsx;
import Common;
import utils.HttpUtil;
import react.product.ProductSelect;
import react.router.Redirect;


/**
 * A box to add an order to a member
 * @author fbarbut
 */
class InsertOrderBox extends react.ReactComponentOfPropsAndState<{contractId:Int,userId:Int,distributionId:Int},{products:Array<ProductInfo>,error:String,selected:Int}>
{

	public function new(props) 
	{
		super(props);	
		state = {products:[],error:null,selected:null};
	}
	
	override function componentDidMount()
	{
		HttpUtil.fetch("/api/product/get/", GET, {contractId:props.contractId},JSON)
		.then(function(data:Dynamic) {
			setState({products:cast data.products, error:null,selected:null});
		}).catchError(function(error) {
			setState(cast {error:error.message});
		});
	}
	
	override public function render(){
		//redirect to orderBox if a product is selected
		var redirect =  if(state.selected!=null) jsx('<$Redirect to="/" />') else null;

		return jsx('
			<div>
				$redirect
				<h3>Choisissez le produit à ajouter</h3>
				<$Error error="${state.error}" />
				<$ProductSelect onSelect=$onSelectProduct products=${state.products} />
			</div>			
		');
	}


	function onSelectProduct(p:ProductInfo){

		trace("on select",p);

		//insert order
		var data = [{id:null,productId:p.id,qt:1,paid:false,invert:false,user2:null} ];
		var req = {
			orders:haxe.Json.stringify(data),
			distributionId : props.distributionId,
			contractId : props.contractId
		};
		var r = HttpUtil.fetch("/api/order/update/"+props.userId, POST, req, JSON);
		r.then(function(d:Dynamic) {
			
			if (Reflect.hasField(d, "error")) {
				setState(cast {error:d.error.message});
			}else{
				//WOOT
				trace("OK");
				//go to OrderBox with a redirect
				setState(cast {selected:p.id});
			}
		}).catchError(function(d) {
			trace("PROMISE ERROR", d);
			setState(cast {error:d.error.message});
		});
		


		
	}
	

	
}