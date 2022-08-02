## Perform and log output of simple arithmetic operations
func simple_math():
    
    ## adding 13 +  14
    tempvar addition = 13 + 14
    %{
        print(ids.addition)
    %}

    ## multiplying 3 * 6
    tempvar multiplication = 3 * 6
    %{
        print(ids.multiplication)
    %}

    ## dividing 6 by 2
    tempvar divisibleDivision = 6 / 2
    %{
        print(ids.divisibleDivision)
    %}

    ## dividing 70 by 2
    tempvar divisibleDivision2 = 70 / 2
    %{
        print(ids.divisibleDivision2)
    %}

    ## dividing 7 by 2 
    tempvar notDivisible = 7 / 2
    %{
        print(ids.notDivisible)
    %}
   
    return ()
end