local extension = Package("joy_ex")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_ex"] = "欢乐-界限突破",
  ["joyex"] = "欢乐界",
}

local diaochan = General(extension, "joyex__diaochan", "qun", 3, 3, General.Female)
local joyex__lijian = fk.CreateActiveSkill{
  name = "joyex__lijian",
  anim_type = "offensive",
  card_num = 1,
  target_num = 2,
  prompt = "#joyex__lijian",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) < 2
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected)
    local target = Fk:currentRoom():getPlayerById(to_select)
    if target:getMark("joyex__lijian-turn") == 0 then
      if #selected == 0 then
        return true
      elseif #selected == 1 then
        return not target:isProhibited(Fk:currentRoom():getPlayerById(selected[1]), Fk:cloneCard("duel"))
      else
        return false
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    for _, id in ipairs(effect.tos) do
      room:setPlayerMark(room:getPlayerById(id), "joyex__lijian-turn", 1)
    end
    room:useVirtualCard("duel", nil, room:getPlayerById(effect.tos[2]), room:getPlayerById(effect.tos[1]), self.name)
  end,
}
local joyex__biyue = fk.CreateTriggerSkill{
  name = "joyex__biyue",
  anim_type = "drawcard",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Finish
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(1 + player:usedSkillTimes("joyex__lijian", Player.HistoryTurn), self.name)
  end,
}
diaochan:addSkill(joyex__lijian)
diaochan:addSkill(joyex__biyue)
Fk:loadTranslationTable{
  ["joyex__diaochan"] = "貂蝉",
  ["joyex__lijian"] = "离间",
  [":joyex__lijian"] = "出牌阶段限两次，你可以弃置一张牌并选择两名本回合未选择过的角色，视为其中一名角色对另一名角色使用一张【决斗】。",
  ["joyex__biyue"] = "闭月",
  [":joyex__biyue"] = "结束阶段，你摸X张牌（X为本回合你发动〖离间〗次数+1）。",
  ["#joyex__lijian"] = "离间：弃置一张牌，选择两名角色，视为第二名角色对第一名角色使用【决斗】",
}

local wangji = General(extension, "joyex__wangji", "wei", 3)
local joyex__qizhi = fk.CreateTriggerSkill{
  name = "joyex__qizhi",
  anim_type = "control",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase ~= Player.NotActive and
      data.firstTarget and data.card.type ~= Card.TypeEquip
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room.alive_players, function(p)
      return not p:isNude() and not table.contains(AimGroup:getAllTargets(data.tos), p.id) end), function(p) return p.id end)
    if #targets == 0 then return end
    local tos = room:askForChoosePlayers(player, targets, 1, 1, "#joyex__qizhi-choose:::"..data.card:getTypeString(), self.name, true)
    if #tos > 0 then
      self.cost_data = tos[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:addPlayerMark(player, "@joyex__qizhi-turn", 1)
    local to = room:getPlayerById(self.cost_data)
    local id = room:askForCardChosen(player, to, "he", self.name)
    local type = Fk:getCardById(id).type
    room:throwCard({id}, self.name, to, player)
    if type == data.card.type and not player.dead then
      player:drawCards(1, self.name)
    elseif type ~= data.card.type and not to.dead then
      to:drawCards(1, self.name)
    end
  end,
}
local joyex__jinqu = fk.CreateTriggerSkill{
  name = "joyex__jinqu",
  anim_type = "drawcard",
  events = {fk.EventPhaseChanging},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.to == Player.Discard
  end,
  on_use = function(self, event, target, player, data)
    player:drawCards(2, self.name)
    local n = player:getHandcardNum() - player:usedSkillTimes("joyex__qizhi", Player.HistoryTurn) - 1
    if n > 0 then
      player.room:askForDiscard(player, n, n, false, self.name, false)
    end
    return true
  end,
}
wangji:addSkill(joyex__qizhi)
wangji:addSkill(joyex__jinqu)
Fk:loadTranslationTable{
  ["joyex__wangji"] = "王基",
  ["joyex__qizhi"] = "奇制",
  [":joyex__qizhi"] = "当你于回合内使用基本牌或锦囊牌指定目标后，你可以弃置不为此牌目标的一名角色一张牌。若弃置的牌与你使用的牌类型相同，"..
  "你摸一张牌；类型不同，其摸一张牌。",
  ["joyex__jinqu"] = "进趋",
  [":joyex__jinqu"] = "弃牌阶段开始前，你可以跳过此阶段并摸两张牌，然后将手牌弃至X张（X为你本回合发动〖奇制〗次数+1）。",
  ["@joyex__qizhi-turn"] = "奇制",
  ["#joyex__qizhi-choose"] = "奇制：弃置一名角色一张牌，若为%arg，你摸一张牌，否则其摸一张牌",
}

return extension
