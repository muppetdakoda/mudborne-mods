-- pet them pets

local PTP_PET_SHRINK_DELAY_SECONDS = 1
local PTP_PET_MAX_SCALE = 4
local PTP_ALARM_PET_CHECK = 2645001

return {

    load = function(mod_id)
        print("Time to PET. THEM. PETS!", mod_id)
        return true
    end,

    mouse = function(action, _, phase)
        if phase == 'after' then
            if action == "pressed" then
                if game.g.highlighted_obj
                        and game.g.highlighted_obj.oid:find('frog')
                        and (game.g.highlighted_obj.props.pet or game.g.highlighted_obj.props.zen)
                then
                    local pet = game.g.highlighted_obj
                    if not pet.ptp_start then

                        pet.ptp_petting = true
                        pet.ptp_shrink = false
                        pet.ptp_scale = 0.6
                        pet.ptp_scale_intent = 0.6

                        local originalStep = pet.scripts.step
                        pet.scripts.step = function(self, delta)
                            originalStep(self, delta)

                            if not self.ptp_start then
                                return
                            end

                            if self.ptp_scale ~= self.ptp_scale_intent then
                                local targetScale = tn.util.ternary(self.ptp_shrink, self.ptp_scale_intent, math.floor(self.ptp_scale_intent))
                                self.ptp_scale = tn.util.eerp(self.ptp_scale, targetScale, 0.2)
                            end

                            if self.ptp_shrink then
                                if self.ptp_scale_intent > 1 then
                                    self.ptp_scale_intent = tn.util.clamp(self.ptp_scale_intent - 0.1, 1, PTP_PET_MAX_SCALE)
                                end
                                if self.ptp_scale < 1.05 then
                                    self.ptp_scale = 1
                                end
                                if self.ptp_scale == 1 then
                                    self.ptp_start = nil
                                    return self:call("cleanup")
                                end
                            end
                        end
                        local originalDraw = pet.scripts.draw
                        pet.scripts.draw = function(self)
                            originalDraw(self)

                            if not self.ptp_start or self.ptp_scale <= 1 then
                                return
                            end

                            local spr = self.props.spr .. self.props.traits.variant
                            local sprite = tn.internals.sprites[self.props.spr .. self.props.traits.variant]
                            local spriteWidth = sprite.width
                            local spriteHeight = sprite.height

                            local fx = math.floor(
                                    self.x - game.g.camera.draw_x
                                            - (spriteWidth * self.ptp_scale - spriteWidth) / 2 * self.scale_x
                                            + tn.util.ternary(self.ptp_scale_intent == PTP_PET_MAX_SCALE, love.math.random(-0.4, 0.4), 0)
                            )
                            local fy = math.floor(
                                    self.y - game.g.camera.draw_y
                                            - (spriteHeight * self.ptp_scale - spriteHeight) / 2)
                                            + tn.util.ternary(self.ptp_scale_intent == PTP_PET_MAX_SCALE, love.math.random(-0.4, 0.4), 0)
                            tn.draw.sprite(spr, self.sprite_frame, fx + self.scale_ox, fy, 0, self.scale_x * self.ptp_scale, self.ptp_scale)
                        end

                        -- petting check
                        pet:defineAlarm(PTP_ALARM_PET_CHECK, (
                                function(self)
                                    if not self.ptp_start then
                                        return
                                    end

                                    if self.ptp_petting then
                                        -- set petting to false
                                        self.ptp_petting = false
                                    elseif not self.ptp_petting then
                                        -- if petting is still false, we have stopped clicking
                                        self.ptp_shrink = true
                                    end

                                    if self.ptp_start then
                                        return self:alarm(PTP_ALARM_PET_CHECK, PTP_PET_SHRINK_DELAY_SECONDS / 2)
                                    end
                                end
                        ))

                        -- cleanup
                        pet.scripts.ptp_cleanup = function(self)
                            self.scripts.step = originalStep
                            self.scripts.draw = originalDraw
                            self.ptp_scale = nil
                            self.ptp_scale_intent = nil
                            self.ptp_shrink = nil
                            self.ptp_petting = nil
                        end

                        pet.ptp_start = true
                        pet:alarm(PTP_ALARM_PET_CHECK, PTP_PET_SHRINK_DELAY_SECONDS / 2)
                    end
                    pet.ptp_petting = true
                    pet.ptp_shrink = false

                    local oldScaleIntentF = math.floor(pet.ptp_scale_intent)
                    local newScaleIntentF = math.floor(pet.ptp_scale_intent + 0.1)
                    if newScaleIntentF > oldScaleIntentF then
                        if newScaleIntentF == PTP_PET_MAX_SCALE then
                            game.g.audio:call("play", "pop")
                        else
                            game.g.audio:call("play", "plop")
                        end
                    end
                    pet.ptp_scale_intent = tn.util.clamp(pet.ptp_scale_intent + 0.1, 1, PTP_PET_MAX_SCALE)
                end
            end
        end
    end
}