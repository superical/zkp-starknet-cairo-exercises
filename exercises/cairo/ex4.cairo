from starkware.cairo.common.alloc import alloc

## Return summation of every number below and up to including n
func calculate_sum(n : felt) -> (sum : felt): 
    alloc_locals

    let (local sum) = sum_to_n(size=n, counter=0)
 
    return(sum)
end

func sum_to_n(size: felt, counter: felt) -> (res : felt): 
    alloc_locals
    if counter == size:
        return(res=size)
    else:
        tempvar nextCounter = counter + 1
        let (local next_res) = sum_to_n(size, nextCounter)
        tempvar res = next_res + counter
        return(res)
    end
end