-- Server only settings. Clients never download this file

-- The server counts the shift itself and pays from its own count. These stop a modified client from
-- reporting work it didn't do. A report that fails a check is ignored (and printed with Config.debug)
Config.security = {
    startDistance = 10.0,  -- m from the foreman to start a shift
    taskDistance = 6.0,    -- m from the work spot to report it done
    minTaskInterval = 5,   -- s between two work spots
}

-- Characters table column the experience is kept in (JSON: { Construction = 12, Sweeping = 3 }). Added on start if missing
Config.database = {
    table = "characters",
    column = "trust",
}
