package react.order.redux.components;

import react.ReactComponent;
import react.ReactMacro.jsx;

//Material UI
import react.mui.CagetteTheme;
import mui.core.Button;


typedef ContractsBoxProps = {
	
	var contractId : Int;
	var multiDistribId : Int;	
	var error : String;
}


/**
 * A box to select a contract to then choose telated products to be added to the orders of the user
 * @author web-wizard
 */
@:connect
class ContractsBox  extends react.ReactComponentOfProps<ContractsBoxProps>
{

	public function new(props) {

		super(props);		
	}	

	override public function render() {	
			
		return jsx('<div>								
						<h3>Choisissez le contrat dont vous voulez voir les produits</h3>
						<Button onClick=${function(){ js.Browser.location.hash = "/"; }} size={Medium} variant={Outlined}>
							${CagetteTheme.getIcon("chevron-left")}&nbsp;&nbsp;Retour
						</Button>
						<Error error=${props.error} />				
						<hr />
						<ContractSelector multiDistribId=${props.multiDistribId} />						
					</div>			
		');
	}
	
	static function mapStateToProps( state : react.order.redux.reducers.OrderBoxReducer.OrderBoxState ) : react.Partial<ContractsBoxProps> {

		return { error : Reflect.field(state, "reduxApp").error };
	}

}