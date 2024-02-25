local extension = Package("joy_ty")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_ty"] = "欢乐-十周年改",
}

local U = require "packages/utility/utility"

-- 在十周年武将基础上修改的武将


local zhoufang = General(extension, "joy__zhoufang", "wu", 3)
local joy__youdi = fk.CreateTriggerSkill{
  name = "joy__youdi",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish and not player:isKongcheng()
  end,
  on_cost = function(self, event, target, player, data)
    local to = player.room:askForChoosePlayers(player, table.map(player.room:getOtherPlayers(player), function(p)
      return p.id end), 1, 1, "#joy__youdi-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local card = room:askForCardChosen(to, player, "h", self.name)
    room:throwCard({card}, self.name, player, to)
    if player.dead or to.dead then return end
    if Fk:getCardById(card).trueName ~= "slash" and not to:isNude() then
      local card2 = room:askForCardChosen(player, to, "he", self.name)
      room:obtainCard(player, card2, false, fk.ReasonPrey)
      if player.dead then return end
      player:drawCards(1, self.name)
    end
    if Fk:getCardById(card).color ~= Card.Black and player.maxHp < 5 and not player.dead then
      room:changeMaxHp(player, 1)
    end
  end,
}
zhoufang:addSkill("duanfa")
zhoufang:addSkill(joy__youdi)
Fk:loadTranslationTable{
  ["joy__zhoufang"] = "周鲂",
  ["joy__youdi"] = "诱敌",
  [":joy__youdi"] = "结束阶段，你可以令一名其他角色弃置你一张手牌，若弃置的牌不是【杀】，则你获得其一张牌并摸一张牌；若弃置的牌不是黑色，且你的体力上限小于5，则你增加1点体力上限。",
  ["#joy__youdi-choose"] = "诱敌：令一名角色弃置你手牌，若不是【杀】，你获得其一张牌并摸一张牌；若不是黑色，你加1点体力上限",
}

local tangji = General(extension, "joy__tangji", "qun", 3, 3, General.Female)
local joy__kangge = fk.CreateTriggerSkill{
  name = "joy__kangge",
  events = {fk.TurnStart, fk.AfterCardsMove},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      if event == fk.TurnStart then
        return target == player
      else
        if player:getMark(self.name) ~= 0 and player:getMark("joy__kangge-turn") < 3 then
          for _, move in ipairs(data) do
            if move.to and move.toArea == Card.PlayerHand and player.room:getPlayerById(move.to):getMark("@@joy__kangge") > 0 and
              player.room:getPlayerById(move.to).phase == Player.NotActive then
              return true
            end
          end
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke(self.name)
    if event == fk.TurnStart then
      room:notifySkillInvoked(player, self.name, "special")
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if p:getMark("@@joy__kangge") > 0 then
          room:setPlayerMark(p, "@@joy__kangge", 0)
        end
      end
      local targets = table.map(room:getOtherPlayers(player), function(p) return p.id end)
      local to = room:askForChoosePlayers(player, targets, 1, 1, "#joy__kangge-choose", self.name, false)
      if #to > 0 then
        to = to[1]
      else
        to = table.random(targets)
      end
      room:setPlayerMark(room:getPlayerById(to), "@@joy__kangge", 1)
    elseif event == fk.AfterCardsMove then
      local n = 0
      for _, move in ipairs(data) do
        if move.to and room:getPlayerById(move.to):getMark("@@joy__kangge") > 0 and move.toArea == Card.PlayerHand then
          n = n + #move.moveInfo
        end
      end
      if n > 0 then
        room:notifySkillInvoked(player, self.name, "drawcard")
        local x = math.min(n, 3 - player:getMark("joy__kangge-turn"))
        room:addPlayerMark(player, "joy__kangge-turn", x)
        player:drawCards(x, self.name)
      end
    end
  end,
}
local joy__kangge_trigger = fk.CreateTriggerSkill{
  name = "#joy__kangge_trigger",
  mute = true,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill("joy__kangge") and target:getMark("@@joy__kangge") > 0 and
      player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "joy__kangge", nil, "#joy__kangge-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("joy__kangge")
    room:notifySkillInvoked(player, "joy__kangge", "support")
    room:doIndicate(player.id, {target.id})
    room:recover({
      who = target,
      num = 1 - target.hp,
      recoverBy = player,
      skillName = "joy__kangge"
    })
  end,
}
local joy__jielie = fk.CreateTriggerSkill{
  name = "joy__jielie",
  anim_type = "defensive",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#joy__jielie-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = table.filter(room:getOtherPlayers(player), function(p) return p:getMark("@@joy__kangge") > 0 end)[1]
    local suit
    if to then
      local suits = {"spade", "heart", "club", "diamond"}
      local choices = table.map(suits, function(s) return Fk:translate("log_"..s) end)
      local choice = room:askForChoice(player, choices, self.name, "#joy__jielie-choice::"..to.id..":"..data.damage)
      suit = suits[table.indexOf(choices, choice)]
      room:doIndicate(player.id, {to.id})
    end
    room:loseHp(player, 1, self.name)
    if to and not to.dead then
      local cards = room:getCardsFromPileByRule(".|.|"..suit, data.damage, "discardPile")
      if #cards > 0 then
        room:moveCards({
          ids = cards,
          to = to.id,
          toArea = Card.PlayerHand,
          moveReason = fk.ReasonJustMove,
          proposer = player.id,
          skillName = self.name,
        })
      end
    end
    return true
  end,
}
joy__kangge:addRelatedSkill(joy__kangge_trigger)
tangji:addSkill(joy__kangge)
tangji:addSkill(joy__jielie)
Fk:loadTranslationTable{
  ["joy__tangji"] = "唐姬",
  ["joy__kangge"] = "抗歌",
  [":joy__kangge"] = "回合开始时，你选择一名其他角色：当该角色于其回合外获得手牌时，你摸等量的牌（每回合最多摸3张）；每轮限一次，当该角色"..
  "进入濒死状态时，你可以令其将体力回复至1点。场上仅能存在一名“抗歌”角色。",
  ["joy__jielie"] = "节烈",
  [":joy__jielie"] = "当你受到伤害时，你可以防止此伤害并选择一种花色，然后你失去1点体力，令“抗歌”角色从弃牌堆中随机获得X张此花色的牌（X为伤害值）。",
  ["#joy__kangge-choose"] = "抗歌：请选择“抗歌”角色",
  ["@@joy__kangge"] = "抗歌",
  ["#joy__kangge-invoke"] = "抗歌：你可以令 %dest 回复体力至1",
  ["#joy__jielie-invoke"] = "节烈：你可以防止你受到的伤害并失去1点体力",
  ["#joy__jielie-choice"] = "节烈：选择一种花色，令“抗歌”角色 %dest 从弃牌堆获得%arg张此花色牌",
}

local zhangxuan = General(extension, "joy__zhangxuan", "wu", 4, 4, General.Female)
local joy__tongli = fk.CreateTriggerSkill{
  name = "joy__tongli",
  anim_type = "offensive",
  events = {fk.TargetSpecified},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Play and data.firstTarget and
      (data.card.type == Card.TypeBasic or data.card:isCommonTrick()) then
      local suits = {}
      for _, id in ipairs(player:getCardIds("h")) do
        if Fk:getCardById(id).suit ~= Card.NoSuit then
          table.insertIfNeed(suits, Fk:getCardById(id).suit)
        end
      end
      return #suits == player:getMark("@joy__tongli-turn")
    end
  end,
  on_use = function(self, event, target, player, data)
    data.additionalEffect = (data.additionalEffect or 0) + player:getMark("@joy__tongli-turn")
  end,

  refresh_events = {fk.AfterCardUseDeclared},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:hasSkill(self, true) and player.phase == Player.Play
  end,
  on_refresh = function(self, event, target, player, data)
    player.room:addPlayerMark(player, "@joy__tongli-turn")
  end,
}
local joy__shezang = fk.CreateTriggerSkill{
  name = "joy__shezang",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (target == player or player == player.room.current) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {1, 2, 3, 4}
    local cards = {}
    local pile = table.simpleClone(room.draw_pile)
    while #pile > 0 and #cards < 4 do
      local id = table.remove(pile, math.random(#pile))
      if table.removeOne(suits, Fk:getCardById(id).suit) then
        table.insert(cards, id)
      end
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonPrey,
        proposer = player.id,
        skillName = self.name,
        moveVisible = true
      })
    end
  end,
}
zhangxuan:addSkill(joy__tongli)
zhangxuan:addSkill(joy__shezang)
Fk:loadTranslationTable{
  ["joy__zhangxuan"] = "张嫙",
  ["joy__tongli"] = "同礼",
  [":joy__tongli"] = "当你于出牌阶段内使用基本牌或普通锦囊牌指定目标后，若你手牌中的花色数等于你此阶段已使用牌的张数，你可令此牌效果额外执行X次（X为你手牌中的花色数）。",
  ["joy__shezang"] = "奢葬",
  [":joy__shezang"] = "每回合限一次，当你或你回合内有角色进入濒死状态时，你可以从牌堆获得不同花色的牌各一张。",
  ["@joy__tongli-turn"] = "同礼",
}







return extension
