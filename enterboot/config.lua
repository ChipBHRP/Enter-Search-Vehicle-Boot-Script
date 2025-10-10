Config = {}


Config.VehicleClasses = {
    ['small'] = 2,  
    ['medium'] = 4, 
    ['large'] = 6,  
    ['non-class'] = 2 
}


Config.GTAClassToCustomMap = {
    -- Max 2
    [0] = 'small',      
    [4] = 'small',      
    [5] = 'small',      
    [6] = 'small',      
    [7] = 'small',      

    -- Max 4
    [1] = 'medium',     
    [3] = 'medium',     
    [2] = 'medium',      
    [9] = 'medium',     

    -- Max 6
    [10] = 'large',     
    [11] = 'large',     
    [12] = 'large',     
    [17] = 'large',     
    [19] = 'large',     
    [20] = 'large',     
    
}

Config.ExcludedVehicleTypes = {
    [8] = true,  -- Motorcycles
    [13] = true, -- Boats
    [14] = true, -- Helicopters
    [15] = true, -- Planes
    [16] = true, -- Service
    [18] = true, -- Cycles
}