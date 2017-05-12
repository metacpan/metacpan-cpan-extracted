package org.maltparser.core.feature.value;

import org.maltparser.core.feature.function.Function;
/**
 *  
 *
 * @author Johan Hall
 * @since 1.0
**/
public class AddressValue extends FunctionValue {
	private Object address;
	
	public AddressValue(Function function) {
		super(function);
		setAddress(null);
	}
	
	public void reset() {
		setAddress(null);
	}
	
	public Class<?> getAddressClass() {
		if (address != null) {
			return address.getClass();
		}
		return null;
	}
	
	public Object getAddress() {
		return address;
	}

	public void setAddress(Object address) {
		this.address = address;
	}

	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		if (!address.equals(((AddressValue)obj).address)) {
			return false;
		}
		return super.equals(obj);
	}
	
	public String toString() {
		return super.toString() + address.toString();
	}
}
