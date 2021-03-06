local DynamicMusic = Class(function(self, inst)
    self.inst = inst
    self.inst:StartUpdatingComponent(self)
    
    self.enabled = true

    self.is_busy = false
    self.busy_timeout = 0
    
    self.playing_danger = false
    self.season = GetSeasonManager() and GetSeasonManager().current_season or SEASONS.AUTUMN
    
    self.inst:ListenForEvent( "gotnewitem", function() self:OnContinueBusy() end )  
    self.inst:ListenForEvent( "dropitem", function() self:OnContinueBusy() end )  
    
    self.inst:ListenForEvent( "attacked", function(inst, dat)
        if self.enabled
           and dat.attacker
           and dat.attacker ~= self.inst
           and not dat.attacker:HasTag("shadow") and not
           dat.attacker:HasTag("thorny")
           and not (dat.attacker.components.burnable and dat.attacker.components.burnable:IsSmoldering()) then
            self:OnStartDanger()
        end
    end )  
    self.inst:ListenForEvent( "doattack", function(inst, dat)
		if self.enabled
            and dat
            and dat.target
            and dat.target.components.combat
		    and not dat.target:HasTag("prey")
			and not dat.target:HasTag("bird")
			and not dat.target:HasTag("wall")
			and not dat.target:HasTag("butterfly")
			and not dat.target:HasTag("shadow")
			and not dat.target:HasTag("veggie")
            and not dat.target:HasTag("smashable") then
			self:OnStartDanger()
		end
	end )  
    self.inst:ListenForEvent( "resurrect", function(inst)
        self:StopPlayingDanger()
    end)
    
  
    self.inst:ListenForEvent( "dusktime", function(it, data) 
            
            if self.enabled and 
                not self.playing_danger and
                data.newdusk then
                self:StopPlayingBusy()
                self.inst.SoundEmitter:PlaySound( "dontstarve/music/music_dusk_stinger")
            end
            
            
        end, GetWorld())      

    self.inst:ListenForEvent( "daytime", function(it, data) 
    
            if self.enabled and 
                data.day > 0 and not self.playing_danger then
                self:StopPlayingBusy()
                self.inst.SoundEmitter:PlaySound( "dontstarve/music/music_dawn_stinger")
            end
            
        end, GetWorld())      

    self.inst:ListenForEvent( "nighttime", function(it, data) 
        end, GetWorld())      
    
    
    inst:ListenForEvent( "builditem", function(it, data) self:OnStartBusy() end)  
    inst:ListenForEvent( "buildstructure", function(it, data) self:OnStartBusy() end)  
    inst:ListenForEvent( "working", function(it, data) self:OnStartBusy() end)  
    
    
end)


function DynamicMusic:StartPlayingBusy()
	if GetWorld():IsRuins() then
		self.inst.SoundEmitter:PlaySound( "dontstarve/music/music_work_ruins", "busy")
	elseif GetWorld():IsCave() then
		self.inst.SoundEmitter:PlaySound( "dontstarve/music/music_work_cave", "busy")
	elseif GetSeasonManager():IsWinter() then
		self.season = SEASONS.WINTER
		self.inst.SoundEmitter:PlaySound( "dontstarve/music/music_work_winter", "busy")
	elseif GetSeasonManager():IsSpring() then
        self.season = SEASONS.SPRING
        self.inst.SoundEmitter:PlaySound( "dontstarve_DLC001/music/music_work_spring", "busy")
    elseif GetSeasonManager():IsSummer() then
        self.season = SEASONS.SUMMER
        self.inst.SoundEmitter:PlaySound( "dontstarve_DLC001/music/music_work_summer", "busy")
    else
        self.season = SEASONS.AUTUMN
		self.inst.SoundEmitter:PlaySound( "dontstarve/music/music_work", "busy")
	end
	
	self.inst.SoundEmitter:SetParameter( "busy", "intensity", 0 )
end

function DynamicMusic:Enable()
    self.enabled = true

end


function DynamicMusic:Disable()
    self.enabled = false
    self:StopPlayingBusy()
    self:StopPlayingDanger()
end

function DynamicMusic:StopPlayingBusy()
    self.inst.SoundEmitter:SetParameter( "busy", "intensity", 0 )
end

function DynamicMusic:OnStartBusy()
	
    if not self.enabled then return end

	if not self.busy_started then
		self.busy_started = true
		self:StartPlayingBusy()
	end

    local day = GetClock():IsDay()
    if day or GetWorld():IsCave() then
        self.busy_timeout = 15
        
        if not self.is_busy then
            self.is_busy = true
            if not self.playing_danger then
                self.inst.SoundEmitter:SetParameter( "busy", "intensity", 1 )
            end
        end
    end
end


function DynamicMusic:OnStartDanger()

    if not self.enabled then return end
    
    self.danger_timeout = 10
    if not self.playing_danger then
        local epic = GetClosestInstWithTag("epic", self.inst, 30)
        local soundpath = nil
        
        if epic then
            if GetWorld():IsRuins() then
				soundpath = "dontstarve/music/music_epicfight_ruins"
            elseif GetWorld():IsCave() then
				soundpath = "dontstarve/music/music_epicfight_cave"
            elseif GetSeasonManager():IsWinter() then
				soundpath = "dontstarve/music/music_epicfight_winter"
			elseif GetSeasonManager():IsSpring() then
                soundpath = "dontstarve_DLC001/music/music_epicfight_spring"
            elseif GetSeasonManager():IsSummer() then
                soundpath = "dontstarve_DLC001/music/music_epicfight_summer"
            else
				soundpath = "dontstarve/music/music_epicfight"
			end
        elseif GetWorld():IsRuins() then
            soundpath = "dontstarve/music/music_danger_ruins"
        elseif GetWorld():IsCave() then
            soundpath = "dontstarve/music/music_danger_cave"
        elseif GetSeasonManager():IsWinter() then
			soundpath = "dontstarve/music/music_danger_winter"
		elseif GetSeasonManager():IsSpring() then
            soundpath = "dontstarve_DLC001/music/music_danger_spring"
        elseif GetSeasonManager():IsSummer() then
            soundpath = "dontstarve_DLC001/music/music_danger_summer"
        else
			soundpath = "dontstarve/music/music_danger"
        end

        self.inst.SoundEmitter:PlaySound(soundpath, "danger")
        self:StopPlayingBusy()
        self.playing_danger = true
    end
end

function DynamicMusic:StopPlayingDanger()
    self.inst.SoundEmitter:KillSound("danger")
    self.playing_danger = false
end

function DynamicMusic:OnContinueBusy()
    if self.is_busy then
        self.busy_timeout = 10
    end
end

function DynamicMusic:OnUpdate(dt)

    if self.danger_timeout and self.danger_timeout > 0 then
        self.danger_timeout = self.danger_timeout - dt
        if self.danger_timeout <= 0 then
            self:StopPlayingDanger()
        end
    end

    if self.busy_timeout and self.busy_timeout > 0 then
        self.busy_timeout = self.busy_timeout - dt
        if self.busy_timeout <= 0 then
            self:StopPlayingBusy()
            self.is_busy = false
        end
    end
    
    
    if not self.is_busy then
		
		if not GetWorld():IsCave() then
		
			if GetSeasonManager().current_season ~= self.season then
				self.inst.SoundEmitter:KillSound("busy")		
				self.season = GetSeasonManager().current_season
				if self.season == SEASONS.WINTER then
					self.inst.SoundEmitter:PlaySound( "dontstarve/music/music_work_winter", "busy")
				elseif self.season == SEASONS.SPRING then
                    self.inst.SoundEmitter:PlaySound( "dontstarve_DLC001/music/music_work_spring", "busy")
                elseif self.season == SEASONS.SUMMER then
                    self.inst.SoundEmitter:PlaySound( "dontstarve_DLC001/music/music_work_summer", "busy")
                else --autumn
					self.inst.SoundEmitter:PlaySound( "dontstarve/music/music_work", "busy")
				end
			end
		end
    end
end



return DynamicMusic

