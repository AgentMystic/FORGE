local static = {}

static.__index = static

function static:next()
    return self.Next
end

function static:setJumping()
    self.Action = "Jumping"
end

function static:setFalling()
    self.Action = "Falling"
end

function static:setJump()
    self.Action = "Jump"
end

function static:setJumpHeightLeft(n)
    self.JumpHeightLeft = n
end

function static:setMovementLeft(n)
    self.MovementLeft = n    
end

function static:setGrounded()
    self.Grounded = true
end

function static:setFCost(n)
    self.FCost = n
end

function public(vector,action,previous,fcost)
    local dynamic = {}
    dynamic.Position = vector
    dynamic.Action = action
    dynamic.Previous = previous 
    dynamic.FCost = fcost
    dynamic.Grounded = false
    dynamic.JumpHeightLeft = 0
    dynamic.MovementLeft = 0
    return setmetatable(dynamic,static)
end

return public