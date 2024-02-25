local extension = Package("joy_mobile")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_mobile"] = "欢乐-手杀改",
}

local U = require "packages/utility/utility"

-- 手杀武将上修改的武将





local joy_mouhuanggai = General(extension, "joy_mou__huanggai", "wu", 4)
local joy_mou__kurou = fk.CreateActiveSkill{
  name = "joy_mou__kurou",
  anim_type = "negative",
  card_num = 0,
  card_filter = Util.FalseFunc,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:loseHp(player, 1, self.name)
    if player.dead then return end
    room:addPlayerMark(player, "@joy_mou__kurou")
    room:broadcastProperty(player, "MaxCards")
    room:changeMaxHp(player, 1)
  end
}
local joy_mou__kurou_maxcards = fk.CreateMaxCardsSkill{
  name = "#joy_mou__kurou_maxcards",
  correct_func = function(self, player)
    return player:getMark("@joy_mou__kurou")
  end,
}
joy_mou__kurou:addRelatedSkill(joy_mou__kurou_maxcards)
local joy_mou__kurou_delay = fk.CreateTriggerSkill{
  name = "#joy_mou__kurou_delay",
  frequency = Skill.Compulsory,
  mute = true,
  events = {fk.TurnStart, fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TurnStart then
      return player == target and player:getMark("@joy_mou__kurou") > 0
    else
      return player == target and player:hasSkill(joy_mou__kurou)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.TurnStart then
      local n = player:getMark("@joy_mou__kurou")
      room:setPlayerMark(player, "@joy_mou__kurou", 0)
      room:broadcastProperty(player, "MaxCards")
      room:changeMaxHp(player, -n)
    else
      room:notifySkillInvoked(player, "joy_mou__kurou", "special")
      player:setSkillUseHistory("joy_mou__kurou", 0, Player.HistoryPhase)
    end
  end,
}
joy_mou__kurou:addRelatedSkill(joy_mou__kurou_delay)
joy_mouhuanggai:addSkill(joy_mou__kurou)

local joy_mou__zhaxiang= fk.CreateTriggerSkill{
  name = "joy_mou__zhaxiang",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.HpLost, fk.PreCardUse, fk.TurnEnd},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.HpLost then
        return true
      elseif event == fk.TurnEnd then
        return player:isWounded()
      else
        return data.card.trueName == "slash" and player:getMark("joy_mou__zhaxiang-turn") < ((player:getLostHp() + 1) // 2)
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local num = (event == fk.HpLost) and data.num or 1
    for i = 1, num do
      self:doCost(event, target, player, data)
      if player.dead then break end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.HpLost then
      player:drawCards(3)
    elseif event == fk.TurnEnd then
      local x = (player:getLostHp() + 1) // 2
      player:drawCards(x)
    else
      data.extraUse = true
      data.disresponsiveList = table.map(player.room.alive_players, Util.IdMapper)
    end
  end,
  
  refresh_events = {fk.CardUsing, fk.HpChanged, fk.MaxHpChanged, fk.EventAcquireSkill, fk.TurnStart},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill(self, true) then
      if event == fk.CardUsing then
        return target == player and data.card.trueName == "slash"
      elseif event == fk.EventAcquireSkill then
        return target == player and data == self and player.room:getTag("RoundCount")
      elseif event == fk.TurnStart then
        return true
      else
        return target == player
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.CardUsing then
      room:addPlayerMark(player, "joy_mou__zhaxiang-turn")
    elseif event == fk.EventAcquireSkill then
      room:setPlayerMark(player, "joy_mou__zhaxiang-turn", #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
        local use = e.data[1]
        return use.from == player.id and use.card.trueName == "slash"
      end, Player.HistoryTurn))
    end
    local x = (player:getLostHp() + 1) // 2
    local used = player:getMark("joy_mou__zhaxiang-turn")
    room:setPlayerMark(player, "@joy_mou__zhaxiang-turn", used.."/"..x)
  end,
}
local joy_mou__zhaxiang_targetmod = fk.CreateTargetModSkill{
  name = "#joy_mou__zhaxiang_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and card.trueName == "slash" and player:hasSkill("joy_mou__zhaxiang")
    and player:getMark("joy_mou__zhaxiang-turn") < ((player:getLostHp() + 1) // 2)
  end,
  bypass_distances = function(self, player, skill, card)
    return card and card.trueName == "slash" and player:hasSkill("joy_mou__zhaxiang")
    and player:getMark("joy_mou__zhaxiang-turn") < ((player:getLostHp() + 1) // 2)
  end,
}
joy_mou__zhaxiang:addRelatedSkill(joy_mou__zhaxiang_targetmod)
joy_mouhuanggai:addSkill(joy_mou__zhaxiang)
Fk:loadTranslationTable{
  ["joy_mou"] = "欢乐谋",
  ["joy_mou__huanggai"] = "谋黄盖",

  ["joy_mou__kurou"] = "苦肉",
  [":joy_mou__kurou"] = "出牌阶段限一次，你可以失去一点体力并令体力上限和手牌上限增加1点直到下回合开始。当你回复体力后，此技能视为未发动。",
  ["@joy_mou__kurou"] = "苦肉",
  ["#joy_mou__kurou_delay"] = "苦肉",

  ["joy_mou__zhaxiang"] = "诈降",
  [":joy_mou__zhaxiang"] = "锁定技，①每当你失去一点体力后，摸三张牌；②回合结束时，你摸X张牌；③每回合你使用的前X张【杀】无距离和次数限制且无法响应（X为你已损失的体力值的一半，向上取整）。",
  ["@joy_mou__zhaxiang-turn"] = "诈降",
}

local machao = General:new(extension, "joy_mou__machao", "shu", 4)
local joy__yuma = fk.CreateTriggerSkill{
  name = "joy__yuma",
  anim_type = "drawcard",
  frequency = Skill.Compulsory,
  events = {fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return end
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and (Fk:getCardById(info.cardId).sub_type == Card.SubtypeDefensiveRide or Fk:getCardById(info.cardId).sub_type == Card.SubtypeOffensiveRide) then
            return true
          end
        end
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    local n = 0
    for _, move in ipairs(data) do
      if move.from == player.id then
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerEquip and (Fk:getCardById(info.cardId).sub_type == Card.SubtypeDefensiveRide or Fk:getCardById(info.cardId).sub_type == Card.SubtypeOffensiveRide) then
            n = n + 1
          end
        end
      end
    end
    for _ = 1, n do
      if  not player:hasSkill(self) then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
  end,
}
local joy__yuma_distance = fk.CreateDistanceSkill{
  name = "#joy__yuma_distance",
  correct_func = function(self, from, to)
    if from:hasSkill(joy__yuma) then
      return -1
    end
  end,
}
joy__yuma:addRelatedSkill(joy__yuma_distance)
machao:addSkill(joy__yuma)
local tieji = fk.CreateTriggerSkill{
  name = "joy_mou__tieji",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and data.to ~= player.id and
      data.card.trueName == "slash"
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:notifySkillInvoked(player, self.name)
    player:broadcastSkillInvoke("mou__tieji", 1)
    local to = room:getPlayerById(data.to)
    data.disresponsive = true
    room:addPlayerMark(to, "@@tieji-turn")
    room:addPlayerMark(to, MarkEnum.UncompulsoryInvalidity .. "-turn")
    local choices = U.doStrategy(room, player, to, {"tieji-zhiqu","tieji-raozheng"}, {"tieji-chuzheng","tieji-huwei"}, self.name, 1)
    local win = true
    if choices[1] == "tieji-zhiqu" and choices[2] ~= "tieji-chuzheng" then
      player:broadcastSkillInvoke("mou__tieji", 2)
      if not to:isNude() then
        local card = room:askForCardChosen(player, to, "he", self.name)
        room:obtainCard(player, card, false, fk.ReasonPrey)
      end
    elseif choices[1] == "tieji-raozheng" and choices[2] ~= "tieji-huwei" then
      player:broadcastSkillInvoke("mou__tieji", 3)
      player:drawCards(2, self.name)
    else
      win = false
      player:broadcastSkillInvoke("mou__tieji", 4)
    end
    if win then
      room:addPlayerMark(player, MarkEnum.SlashResidue.."-turn")
      if not player:isKongcheng() and #room:askForDiscard(player, 1, 1, false, self.name, true, ".", "#joy_mou__tieji-discard") > 0 then
        local ids = room:getCardsFromPileByRule("slash")
        if #ids > 0 then
          room:moveCardTo(ids, Card.PlayerHand, player, fk.ReasonPrey, self.name)
        end
      end
    end
  end,
}
machao:addSkill(tieji)
Fk:loadTranslationTable{
  ["joy_mou__machao"] = "谋马超",
  ["#joy_mou__machao"] = "阻戎负勇",
  ["joy__yuma"] = "驭马",
  [":joy__yuma"] = "锁定技，你计算与其他角色距离-1；每当你失去装备区一张坐骑牌后，你摸两张牌。",
  ["joy_mou__tieji"] = "铁骑",
  [":joy_mou__tieji"] = "每当你使用【杀】指定其他角色为目标后，你可令其不能响应此【杀】，且所有非锁定技失效直到回合结束。然后你与其进行谋弈：①“直取敌营”，你获得其一张牌；②“扰阵疲敌”，你摸两张牌。若你谋奕成功，本回合使用【杀】上次数限+1，且可以弃置一张手牌，获得一张【杀】。",
  ["#joy_mou__tieji-discard"] = "铁骑：可以弃置一张手牌，获得一张【杀】",
}




return extension
