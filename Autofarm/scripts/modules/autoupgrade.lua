local autoupgrade = {}

function autoupgrade.CallAutoUpgrade()
    local hero = Heroes.GetLocal()
    if not hero then return end 

    if Hero.GetAbilityPoints(hero) == 1 then
        local abilityList = Panorama.GetPanelByName("DOTAAbilityList" , true)
        local talentList  = Panorama.GetPanelByName("DOTAHUDLevelStatsFrame" , true)
        if not abilityList then return end
        if not talentList then return end

        if talentList:HasClass("recommended_upgrade") then
            local talentBranch = Panorama.GetPanelByName("DOTAStatBranch", false)
            if talentBranch then
                Engine.RunScript("$.DispatchEvent('DOTAHUDToggleStatBranchVisibility')", talentList)
                print('1')
                local statColumn = talentBranch:FindChildTraverse("StatBranchColumn")   
                for i = 0 , statColumn:GetChildCount() - 1 do 
                    local upgradeOption = statColumn:GetChild(i)
                    local leftOption = upgradeOption:GetChild(0):GetChild(0)
                    local rightOption = upgradeOption:GetChild(1):GetChild(0)
                    if leftOption:HasClass("RecommendedUpgrade") then
                        local id = leftOption:GetID() 
                        local num = tonumber(id:match("%d+"))     
                        Engine.RunScript("$.DispatchEvent('DOTAHUDStatBranchUpgrade', " .. num .. ")", leftOption)
                        Engine.RunScript("$.DispatchEvent('DOTAHUDToggleStatBranchVisibility')", talentList)
                    elseif rightOption:HasClass("RecommendedUpgrade") then
                        local id = rightOption:GetID() 
                        local num = tonumber(id:match("%d+"))     
                        Engine.RunScript("$.DispatchEvent('DOTAHUDStatBranchUpgrade', " .. num .. ")", rightOption)
                        Engine.RunScript("$.DispatchEvent('DOTAHUDToggleStatBranchVisibility')", talentList)
                    end 

                end

            end
        elseif NPC.GetCurrentLevel(hero) >= 26 then
            local talentBranch = Panorama.GetPanelByName("DOTAStatBranch", false)
            if talentBranch then
                Engine.RunScript("$.DispatchEvent('DOTAHUDToggleStatBranchVisibility')", talentList)
                print('2')

                local statColumn = talentBranch:FindChildTraverse("StatBranchColumn")

                for i = 0, statColumn:GetChildCount() - 1 do
                    local upgradeOption = statColumn:GetChild(i)
                    local leftOption = upgradeOption:GetChild(0):GetChild(0)
                    local rightOption = upgradeOption:GetChild(1):GetChild(0)

                    if upgradeOption:HasClass("LeftBranchActive") then
                        local id = leftOption:GetID() 
                        local num = tonumber(id:match("%d+"))     
                        Engine.RunScript("$.DispatchEvent('DOTAHUDStatBranchUpgrade', " .. num .. ")", leftOption)
                        Engine.RunScript("$.DispatchEvent('DOTAHUDToggleStatBranchVisibility')", talentList)
                    elseif upgradeOption:HasClass("RightBranchActive") then
                        local id = rightOption:GetID() 
                        local num = tonumber(id:match("%d+"))     
                        Engine.RunScript("$.DispatchEvent('DOTAHUDStatBranchUpgrade', " .. num .. ")", rightOption)
                        Engine.RunScript("$.DispatchEvent('DOTAHUDToggleStatBranchVisibility')", talentList)
                    end

                
                end
    
            end
        end
        for i = 0, abilityList:GetChildCount() - 1 do
            local ability = abilityList:GetChild(i)
            if ability:HasClass("recommended_upgrade") then
                local levelUpButton = ability:FindChildTraverse("LevelUpTab")
                print(levelUpButton)
                Engine.RunScript("$.DispatchEvent('DOTAHUDLevelUpAbility')", ability)

            end
        end
    end

end


return autoupgrade