
## I AM NOT DONE

%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_unsigned_div_rem, uint256_sub
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import unsigned_div_rem, assert_le_felt, assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.hash_state import hash_init, hash_update 
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor

struct Square:    
    member square_commit: felt
    member square_reveal: felt
    member shot: felt
end

struct Player:    
    member address: felt
    member points: felt
    member revealed: felt
end

struct Game:        
    member player1: Player
    member player2: Player
    member next_player: felt
    member last_move: (felt, felt)
    member winner: felt
end

@storage_var
func grid(game_idx : felt, player : felt, x : felt, y : felt) -> (square : Square):
end

@storage_var
func games(game_idx : felt) -> (game_struct : Game):
end

@storage_var
func game_counter() -> (game_counter : felt):
end

func hash_numb{pedersen_ptr : HashBuiltin*}(numb : felt) -> (hash : felt):

    alloc_locals
    
    let (local array : felt*) = alloc()
    assert array[0] = numb
    assert array[1] = 1
    let (hash_state_ptr) = hash_init()
    let (hash_state_ptr) = hash_update{hash_ptr=pedersen_ptr}(hash_state_ptr, array, 2)   
    tempvar pedersen_ptr :HashBuiltin* = pedersen_ptr       
    return (hash_state_ptr.current_hash)
end


## Provide two addresses
@external
func set_up_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player1 : felt, player2 : felt):
    let (game_counter_val) = game_counter.read()

    let game = Game(
        player1=Player(address=player1, points=0, revealed=0),
        player2=Player(address=player2, points=0, revealed=0),
        next_player=0,
        last_move=(0, 0),
        winner=0
    )

    tempvar new_game_counter = game_counter_val + 1
    game_counter.write(new_game_counter)

    games.write(game_counter_val, game)
    return ()
end

@view 
func check_caller{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(caller : felt, game : Game) -> (valid : felt):
    if caller == game.player1.address: 
        %{ print("Caller is player 1") %}
        return (TRUE)
    else:
        if caller == game.player2.address:
            %{ print("Caller is player 2") %}
            return (TRUE)
        else:
            %{ print("Caller is not a player") %}
            return (FALSE)
        end
    end
end

@view
func check_hit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(square_commit : felt, square_reveal : felt) -> (hit : felt):
    alloc_locals
    let (local hashed_square_reveal) = hash_numb(square_reveal)

    with_attr error_message("Square commit and reveal do not match"):
        assert square_commit = hashed_square_reveal
    end
    
    let (_, r) = unsigned_div_rem(square_reveal, 2)
    let (hit) = is_le(1, r)
    return (hit)
end

@external
func bombard{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(game_idx : felt, x : felt, y : felt, square_reveal : felt):
    alloc_locals

    let (game_val) = games.read(game_idx)
    let (caller) = get_caller_address()
    let (is_caller_player) = check_caller(caller, game_val)

    # If first move, any player can reveal his square
    # If non-first move, the next player reveals the square from the previous player's last move
    # Check if the square has been hit

    if game_val.next_player == 0:
        with_attr error_message("Caller is not a player"):
            assert is_caller_player = TRUE
        end
        let (target_square) = grid.read(game_idx, caller, x, y)
        let (new_game) = _update_game(game_val, caller, FALSE, x, y)
        let new_target_square = Square(square_commit=target_square.square_commit, square_reveal=0, shot=TRUE)

        grid.write(game_idx, caller, x, y, new_target_square)
        games.write(game_idx, new_game)

        return ()
    else:
        with_attr error_message("Caller is not next player"):
            assert caller = game_val.next_player
        end

        let (previous_player) = _get_previous_player(game_val, caller)
        let (target_square) = grid.read(game_idx, caller, x, y)
        let (last_move_square) = grid.read(game_idx, previous_player, game_val.last_move[0], game_val.last_move[1])

        let (is_hit) = check_hit(last_move_square.square_commit, square_reveal)
        let (new_game) = _update_game(game_val, caller, is_hit, x, y)
        
        let new_target_square = Square(square_commit=target_square.square_commit, square_reveal=0, shot=TRUE)
        let new_last_move_square = Square(square_commit=last_move_square.square_commit, square_reveal=square_reveal, shot=last_move_square.shot)

        grid.write(game_idx, caller, x, y, new_target_square)
        grid.write(game_idx, previous_player, game_val.last_move[0], game_val.last_move[1], new_last_move_square)
        games.write(game_idx, new_game)

        return ()
    end
end

func _get_previous_player{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(game : Game, caller : felt) -> (previous_player : felt):
    if caller == game.player1.address:
        return (game.player2.address)
    else:
        return (game.player1.address)
    end
end

func _update_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(game: Game, caller: felt, is_hit: felt, x: felt, y: felt) -> (game: Game):
    alloc_locals

    let (player1_points, player2_points, next_player, winner) = _compute_new_game_state(game, caller, is_hit)

    # local new_game: Game
    # assert new_game.player1.address = game.player1.address
    # assert new_game.player2.address = game.player2.address
    # assert new_game.last_move = (x, y)
    # assert new_game.player1.points = player1_points
    # assert new_game.player2.points = player2_points
    # assert new_game.next_player = next_player
    # assert new_game.winner = winner

    local new_game: Game = Game(
        player1=Player(address=game.player1.address, points=player1_points, revealed=0),
        player2=Player(address=game.player2.address, points=player2_points, revealed=0),
        next_player=next_player,
        last_move=(x, y),  
        winner=winner
    )


    # %{
    #     print("player1_points:", ids.player1_points)
    #     print("player2_points:", ids.player2_points)
    #     print("next_player:", ids.next_player)
    #     print("winner:", ids.winner)
    # %}
    
    return (game=new_game)
end

func _compute_new_game_state{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(game: Game, caller: felt, is_hit: felt) -> (player1_points: felt, player2_points: felt, next_player: felt, winner: felt):    
    if is_hit == TRUE:
        if caller == game.player1.address:
            tempvar new_points = game.player2.points + 1
            if new_points == 4:
                tempvar winner = game.player2.address
            else:
                tempvar winner = 0
            end
            return (player1_points=game.player1.points, player2_points=new_points, next_player=game.player2.address, winner=winner)
        else:
            tempvar new_points = game.player1.points + 1
            if new_points == 4:
                tempvar winner = game.player1.address
            else:
                tempvar winner = 0
            end
            return (player1_points=new_points, player2_points=game.player2.points, next_player=game.player1.address, winner=winner)
        end
    else:
        if caller == game.player1.address:
            return (player1_points=game.player1.points, player2_points=game.player2.points, next_player=game.player2.address, winner=0)
        else:
            return (player1_points=game.player1.points, player2_points=game.player2.points, next_player=game.player1.address, winner=0)
        end
    end
end

## Check malicious call
@external
func add_squares{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(idx : felt, game_idx : felt, hashes_len : felt, hashes : felt*, player : felt, x: felt, y: felt):
    alloc_locals

    let (game_val) = games.read(game_idx)
    let (caller) = get_caller_address()
    let (is_caller_player) = check_caller(caller, game_val)

    with_attr error_message("Caller is not a player"):
        assert is_caller_player = TRUE
    end

    load_hashes(idx, game_idx, hashes_len, hashes, player, x, y)

    return ()
end

func assert_caller_is_player{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(game : Game) -> (res : felt):
    let (caller) = get_caller_address()
    let (is_caller_player) = check_caller(caller, game)

    with_attr error_message("Caller is not a player"):
        assert is_caller_player = TRUE
    end

    return ()
end

## loops until array length
func load_hashes{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(idx : felt, game_idx : felt, hashes_len : felt, hashes : felt*, player : felt, x: felt, y: felt):
    let len_diff = hashes_len - idx
    if len_diff == 1:
        return ()
    else:
        grid.write(game_idx, player, x, y, Square(square_commit=hashes[idx], square_reveal=0, shot=FALSE))
        tempvar new_idx = idx + 1
        if x == 4:
            tempvar new_x = 0
            tempvar new_y = y + 1
        else:
            tempvar new_x = x + 1
            tempvar new_y = y
        end
        load_hashes(new_idx, game_idx, hashes_len, hashes, player, new_x, new_y)
        return ()
    end
end
