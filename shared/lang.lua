Lang = {}

function __(name)
    return Lang[name] and Lang[name] .. "" or ("#" .. tostring(name))
end

-- * ==================================================
-- * MANAGER MENU
-- * ==================================================
Lang.talk = "Talk to the foreman"
Lang.menuSubtitle = "%s"
Lang.experience = "Experience"
Lang.experienceDesc = "Shifts you've finished in full. More experience, better pay."
Lang.shiftPay = "Pay for a full shift"
Lang.spots = "Work spots"
Lang.progress = "Done"
Lang.quality = "Quality"
Lang.startJob = "Start working"
Lang.startJobDesc = "Pick up the tools and get to work."
Lang.switchJobDesc = "You stop your %s shift and start here."
Lang.finishJob = "Finish working"
Lang.finishJobDesc = "Get paid for what you've done. Do more than half the spots to get paid, all of them for experience."
Lang.close = "Close"

-- * ==================================================
-- * WORKING
-- * ==================================================
Lang.marked = "Go to the marked location"
Lang.finishedTasks = "Finished for the day, head back to the foreman"
Lang.messedUp = "You make a mess and have to start over"
Lang.dropped = "You dropped it, go and pick up another"
Lang.insufficientWork = "Your work wasn't enough to be paid for"
Lang.paid = "You get paid $%s"
Lang.levelUp = "%s experience: %d"
Lang.notStarted = "The foreman can't take you on right now"
Lang.tooFar = "You are too far from the work spot"
Lang.foreman = "Foreman"

-- * ==================================================
-- * HAMMER MINIGAME (html/)
-- * ==================================================
Lang.minigame = {
    title = "Nail it down",
    hint = "Strike the nail as the ring closes on it",
    ready = "Get ready",
    perfect = "Perfect",
    good = "Good",
    early = "Too early",
    late = "Too late",
    success = "Nailed it",
    failed = "Bent the nail",
    timeUp = "Out of time",
    nails = "Nails",
    bent = "Mistakes",
    strike = "Strike",
    giveUp = "Give up",
}
