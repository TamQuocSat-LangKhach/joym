local extension = Package("joy_yj")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_yj"] = "欢乐-一将成名",
}

--曹植 于禁 荀攸 曹彰 步练师 刘封 伏皇后 周仓 曹休 孙登 徐氏 曹节
local xunyou = General(extension, "joy__xunyou", "wei", 3)
local joy__qice = fk.CreateViewAsSkill{
  name = "joy__qice",
  prompt = "#joy__qice",
  interaction = function()
    local names = {}
    for _, id in ipairs(Fk:getAllCardIds()) do
      local card = Fk:getCardById(id)
      if card:isCommonTrick() and not card.is_derived and card.skill:canUse(Self, card) then
        table.insertIfNeed(names, card.name)
      end
    end
    return UI.ComboBox {choices = names}
  end,
  card_filter = function(self, to_select, selected)
    return Fk:currentRoom():getCardArea(to_select) == Player.Hand
  end,
  view_as = function(self, cards)
    if #cards == 0 or not self.interaction.data then return end
    local card = Fk:cloneCard(self.interaction.data)
    card:addSubcards(cards)
    card.skillName = self.name
    return card
  end,
  enabled_at_play = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
}
local joy__zhiyu = fk.CreateTriggerSkill{
  name = "joy__zhiyu",
  anim_type = "masochism",
  events = {fk.Damaged},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:drawCards(2, self.name)
    if not player.dead and not player:isKongcheng() then
      room:askForDiscard(player, 1, 1, false, self.name, false)
    end
    local cards = table.simpleClone(player:getCardIds("h"))
    player:showCards(cards)
    if player.dead or not data.from or data.from.dead or data.from:getHandcardNum() <= player:getHandcardNum() then return end
    if table.every(cards, function(id) return #cards == 0 or Fk:getCardById(id).color == Fk:getCardById(cards[1]).color end) and
      room:askForSkillInvoke(player, self.name, nil, "#joy__zhiyu-discard::"..data.from.id) then
      room:doIndicate(player.id, {data.from.id})
      local n = data.from:getHandcardNum() - player:getHandcardNum()
      room:askForDiscard(data.from, n, n, false, self.name, false)
    end
  end,
}
xunyou:addSkill(joy__qice)
xunyou:addSkill(joy__zhiyu)
Fk:loadTranslationTable{
  ["joy__xunyou"] = "荀攸",
  ["joy__qice"] = "奇策",
  [":joy__qice"] = "出牌阶段限一次，你可以将任意张手牌当任意一张普通锦囊牌使用。",
  ["joy__zhiyu"] = "智愚",
  [":joy__zhiyu"] = "当你受到伤害后，你可以摸两张牌并弃置一张牌，然后展示所有手牌，若颜色均相同，你可以令伤害来源将手牌弃至与你相同。",
  ["#joy__qice"] = "奇策：你可以将任意张手牌当一张普通锦囊牌使用",
  ["#joy__zhiyu-discard"] = "智愚：你可以令 %dest 将手牌弃至与你相同",
}

local fuhuanghou = General(extension, "joy__fuhuanghou", "qun", 3, 3, General.Female)
local joy__zhuikong = fk.CreateTriggerSkill{
  name = "joy__zhuikong",
  anim_type = "control",
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name) and target ~= player and not player:isKongcheng() and not target:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, data, "#joy__zhuikong-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:doIndicate(player.id, {target.id})
    local pindian = player:pindian({target}, self.name)
    if pindian.results[target.id].winner == player then
      room:setPlayerMark(target, "joy__zhuikong_prohibit-turn", 1)
    else
      room:setPlayerMark(player, "joy__zhuikong-turn", 1)
    end
  end
}
local joy__zhuikong_prohibit = fk.CreateProhibitSkill{
  name = "#joy__zhuikong_prohibit",
  is_prohibited = function(self, from, to, card)
    return from:getMark("joy__zhuikong_prohibit-turn") > 0 and from ~= to
  end,
}
local joy__zhuikong_distance = fk.CreateDistanceSkill{
  name = "#joy__zhuikong_distance",
  fixed_func = function(self, from, to)
    if to:usedSkillTimes("joy__zhuikong", Player.HistoryTurn)> 0 and to:getMark("joy__zhuikong-turn") > 0 then
      return 1
    end
  end,
}
local joy__qiuyuan = fk.CreateTriggerSkill{
  name = "joy__qiuyuan",
  anim_type = "control",
  events = {fk.TargetConfirming},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and data.card.trueName == "slash"
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return p.id ~= data.from end), function (p) return p.id end)
    local tos = room:askForChoosePlayers(player, targets, 1, 3, "#joy__qiuyuan-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:sortPlayersByAction(self.cost_data)
    room:doIndicate(player.id, self.cost_data)
    for _, id in ipairs(self.cost_data) do
      local p = room:getPlayerById(id)
      if not p.dead then
        local yes = true
        if not player.dead then
          local card = room:askForCard(p, 1, 1, false, self.name, true, "jink", "#joy__qiuyuan-give:"..player.id.."::"..data.card:toLogString())
          if #card > 0 then
            room:obtainCard(player.id, card[1], true, fk.ReasonGive)
            yes = false
          end
        end
        if yes then
          TargetGroup:pushTargets(data.targetGroup, id)
          if not p:isNude() then
            room:askForDiscard(p, 1, 1, true, self.name, false)
          end
        end
      end
    end
  end,
}
joy__zhuikong:addRelatedSkill(joy__zhuikong_prohibit)
joy__zhuikong:addRelatedSkill(joy__zhuikong_distance)
fuhuanghou:addSkill(joy__zhuikong)
fuhuanghou:addSkill(joy__qiuyuan)
Fk:loadTranslationTable{
  ["joy__fuhuanghou"] = "伏皇后",
  ["joy__zhuikong"] = "惴恐",
  [":joy__zhuikong"] = "其他角色回合开始时，你可以与其拼点：若你赢，其本回合不能对除其以外的角色使用牌；若你没赢，本回合其与你的距离视为1。",
  ["joy__qiuyuan"] = "求援",
  [":joy__qiuyuan"] = "当你成为【杀】的目标时，你可以令除使用者以外至多三名角色依次选择一项：1.交给你一张【闪】；2.成为此【杀】的目标并弃置一张牌。",
  ["#joy__zhuikong-invoke"] = "惴恐：你可以与 %dest 拼点，若赢则其本回合不能对除其以外的角色使用牌",
  ["#joy__qiuyuan-choose"] = "求援：你可以令至多三名角色选择：交给你一张【闪】，或成为此【杀】的目标并弃置一张牌",
  ["#joy__qiuyuan-give"] = "求援：你需交给 %src 一张【闪】，否则你也成为此%arg目标并弃置一张牌",
}

return extension
