%lang starknet
from starkware.cairo.common.uint256 import Uint256, uint256_sub
@contract_interface
namespace IErc20:    

    func balanceOf(account: felt) -> (res : Uint256):
    end

    func transfer(recipient: felt, amount: Uint256) -> (success: felt):
    end

    func burn(amount: Uint256) -> (level_granted: felt):
    end

    func faucet(amount : Uint256) -> (success: felt):
    end

    func exclusive_faucet(amount : Uint256) -> (success: felt):
    end

    func check_whitelist(account: felt) -> (allowed_v: felt): 
    end

    func request_whitelist() -> (level_granted: felt):
    end    

    func get_admin() -> (admin_address: felt):
    end

    func transferFrom(sender: felt, recipient: felt, amount: Uint256):
    end

    func approve(spender: felt, amount: Uint256):
    end
end
