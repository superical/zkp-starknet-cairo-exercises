## I AM NOT DONE

%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_unsigned_div_rem, uint256_sub, uint256_mul
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import unsigned_div_rem, assert_le_felt
from starkware.cairo.common.bool import TRUE, FALSE

from starkware.cairo.common.math import (
    assert_not_zero,
    assert_not_equal,
    assert_nn,
    assert_le,
    assert_lt,    
    assert_in_range,
)


from exercises.contracts.erc20.ERC20_base import (
    ERC20_name,
    ERC20_symbol,
    ERC20_totalSupply,
    ERC20_decimals,
    ERC20_balanceOf,
    ERC20_allowance,
    ERC20_mint,

    ERC20_initializer,       
    ERC20_transfer,    
    ERC20_burn,

    ERC20_transferFrom,
    ERC20_approve
)

@storage_var
func admin() -> (admin: felt):
end

@storage_var
func whitelist(account_id: felt) -> (res: felt):
end

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr: felt*, 
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        name: felt,
        symbol: felt,
        initial_supply: Uint256,
        recipient: felt
    ):
    ERC20_initializer(name, symbol, initial_supply, recipient)  
    admin.write(recipient)  
    return ()
end

#
# Getters
#

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name: felt):
    let (name) = ERC20_name()
    return (name)
end


@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol: felt):
    let (symbol) = ERC20_symbol()
    return (symbol)
end

@view
func totalSupply{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (totalSupply: Uint256):
    let (totalSupply: Uint256) = ERC20_totalSupply()
    return (totalSupply)
end

@view
func decimals{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (decimals: felt):
    let (decimals) = ERC20_decimals()
    return (decimals)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (balance: Uint256):
    let (balance: Uint256) = ERC20_balanceOf(account)
    return (balance)
end

@view
func allowance{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner: felt, spender: felt) -> (remaining: Uint256):
    let (remaining: Uint256) = ERC20_allowance(owner, spender)
    return (remaining)
end

@view
func get_admin{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (admin_address: felt):
    let (admin_address: felt) = admin.read()
    return (admin_address)
end

#
# Externals
#


@external
func transfer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(recipient: felt, amount: Uint256) -> (success: felt):

    let (_, r) = uint256_unsigned_div_rem(amount, Uint256(low=2, high=0))

    with_attr error_message("Transfer amount is not even"):
        assert r = Uint256(low=0, high=0)
    end

    ERC20_transfer(recipient, amount)    
    return (1)
end

@external
func transferFrom{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        sender: felt, 
        recipient: felt, 
        amount: Uint256
    ):
    ERC20_transferFrom(sender, recipient, amount)   
    return ()
end

@external
func approve{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(spender: felt, amount: Uint256):
    ERC20_approve(spender, amount)    
    return ()
end

@external
func faucet{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(amount:Uint256) -> (success: felt):
    let (is_within_limit) = uint256_le(amount, Uint256(low=10000, high=0))
    with_attr error_message("Maximum 10,000 tokens only"):
        assert_not_zero(is_within_limit)
    end

    let (caller) = get_caller_address()
    ERC20_mint(caller, amount)
    return (1)
end


@external
func burn{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(amount: Uint256) -> (success: felt):  
    alloc_locals

    let (caller) = get_caller_address()

    let (local caller_bal) = ERC20_balanceOf(caller)
    let (sufficient_bal) = uint256_le(amount, caller_bal)

    with_attr error_message("Insufficient balance"):
        assert_not_zero(sufficient_bal)
    end

    tempvar percentage = Uint256(low=10 * 100, high=0)
    let (local numerator, _) = uint256_mul(amount, percentage)
    let (tax, _) = uint256_unsigned_div_rem(numerator, Uint256(low=10000, high=0))
    let (remaining) = uint256_sub(amount, tax)
    let (admin) = get_admin()

    ERC20_transfer(admin, tax)
    ERC20_burn(caller, remaining)

    return (1)
end

@external
func request_whitelist{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (success: felt):
    alloc_locals
    
    let (local caller) = get_caller_address()

    let (is_whitelisted) = check_whitelist(caller)
    assert is_whitelisted = FALSE

    whitelist.write(caller, TRUE)

    return (TRUE)
end

@external
func check_whitelist{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account: felt) -> (is_whitelisted: felt):
    let (is_whitelisted) = whitelist.read(account)

    return (is_whitelisted)
end

@external
func exclusive_faucet{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(amount:Uint256) -> (success: felt):
    let (caller) = get_caller_address()
    let (is_whitelisted) = check_whitelist(caller)

    with_attr error_message("Not whitelisted"):
        assert is_whitelisted = TRUE
    end

    ERC20_mint(caller, amount)
    return (TRUE)
end