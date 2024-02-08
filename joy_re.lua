local extension = Package("joy_re")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_re"] = "欢乐-RE",
}

local U = require "packages/utility/utility"

--在原技能组上修改的武将
--群马超 魏庞德 张宝 何太后 孙鲁育 SP孙尚香 孙皓 麹义 神甄姬 张梁 群太史慈 吴庞统 周鲂 张昌蒲 唐姬 杜夫人 张嫙

local sunshangxiang = General(extension, "joysp__sunshangxiang", "shu", 3, 3, General.Female)
local joy__liangzhu = fk.CreateTriggerSkill{
  name = "joy__liangzhu",
  anim_type = "support",
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Play
  end,
  on_cost = function(self, event, target, player, data)
    local all_choices = {"Cancel", "draw1", "joy__liangzhu_draw2::"..target.id, "joy__liangzhu_prey::"..target.id}
    local choices = table.simpleClone(all_choices)
    if target:getEquipment(Card.SubtypeWeapon) == nil then
      table.removeOne(choices, choices[4])
    end
    local choice = player.room:askForChoice(player, choices, self.name, "#joy__liangzhu-choice::"..target.id, false, all_choices)
    if choice ~= "Cancel" then
      self.cost_data = choice
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if self.cost_data == "draw1" then
      player:drawCards(1, self.name)
    elseif self.cost_data[15] == "d" then
      room:doIndicate(player.id, {target.id})
      target:drawCards(2, self.name)
    else
      room:doIndicate(player.id, {target.id})
      room:obtainCard(player, target:getEquipment(Card.SubtypeWeapon), true, fk.ReasonPrey)
    end
  end,
}
local joy__fanxiang = fk.CreateTriggerSkill{
  name = "joy__fanxiang",
  frequency = Skill.Wake,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and
      player.phase == Player.Start and
      player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  can_wake = function(self, event, target, player, data)
    return player:usedSkillTimes("joy__liangzhu", Player.HistoryGame) > 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if player:isWounded() then
      room:recover({
        who = player,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    end
    room:handleAddLoseSkills(player, "xiaoji|joy__wujian", nil)
  end,
}
local joy__wujian = fk.CreateViewAsSkill{
  name = "joy__wujian",
  anim_type = "offensive",
  pattern = "slash",
  prompt = "#joy__wujian",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) == Player.Equip and
      Self:getMark("joy__wujian_"..Fk:getCardById(to_select):getSubtypeString().."-phase") == 0
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("slash")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
  before_use = function (self, player, use)
    player.room:setPlayerMark(player, "joy__wujian_"..Fk:getCardById(use.card.subcards[1]):getSubtypeString().."-phase", 1)
    use.extraUse = true
  end,
  enabled_at_response = function(self, player, response)
    return not response and player.phase == Player.Play
  end,
}
local joy__wujian_targetmod = fk.CreateTargetModSkill{
  name = "#joy__wujian_targetmod",
  bypass_times = function(self, player, skill, scope, card)
    return card and table.contains(card.skillNames, "joy__wujian")
  end,
}
joy__wujian:addRelatedSkill(joy__wujian_targetmod)
sunshangxiang:addSkill(joy__liangzhu)
sunshangxiang:addSkill(joy__fanxiang)
sunshangxiang:addRelatedSkill("xiaoji")
sunshangxiang:addRelatedSkill(joy__wujian)
Fk:loadTranslationTable{
  ["joysp__sunshangxiang"] = "孙尚香",
  ["joy__liangzhu"] = "良助",
  [":joy__liangzhu"] = "当一名角色于其出牌阶段内回复体力后，你可以选择一项：1.摸一张牌；2.令其摸两张牌；3.获得其装备区内的武器牌。",
  ["joy__fanxiang"] = "返乡",
  [":joy__fanxiang"] = "觉醒技，准备阶段，若你发动过〖良助〗，你加1点体力上限并回复1点体力，然后获得〖枭姬〗和〖舞剑〗。",
  ["joy__wujian"] = "舞剑",
  [":joy__wujian"] = "出牌阶段，你可以将装备区内的装备当不计次数的【杀】使用，每种类别每阶段限一次。",
  ["#joy__liangzhu-choice"] = "良助：你可以对 %dest 发动“良助”，选择执行一项",
  ["joy__liangzhu_draw2"] = "令 %dest 摸两张牌",
  ["joy__liangzhu_prey"] = "获得 %dest 的武器",
  ["#joy__wujian"] = "舞剑：你可以将装备区内的装备当不计次数的【杀】使用",
}

local godzhenji = General(extension, "joy__godzhenji", "god", 3, 3, General.Female)
local joy__shenfu = fk.CreateTriggerSkill{
  name = "joy__shenfu",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Finish
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    if player:getHandcardNum() % 2 == 1 then
      while true do
        local tos = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player), Util.IdMapper), 1, 1, "#shenfu-damage", self.name, true)
        if #tos == 0 then break end
        n = n + 1
        local to = room:getPlayerById(tos[1])
        room:damage{
          from = player,
          to = to,
          damage = 1,
          damageType = fk.ThunderDamage,
          skillName = self.name,
        }
        if not to.dead then
          break
        end
      end
    else
      while true do
        local tos = room:askForChoosePlayers(player, table.map(table.filter(room.alive_players, function(p)
          return p:getMark("joy__shenfu-turn") == 0 end), Util.IdMapper), 1, 1, "#shenfu-hand", self.name, true)
        if #tos == 0 then break end
        n = n + 1
        local to = room:getPlayerById(tos[1])
        room:setPlayerMark(to, "joy__shenfu-turn", 1)
        if to:isKongcheng() then
          to:drawCards(1, self.name)
        else
          local choice = room:askForChoice(player, {"shenfu_draw", "shenfu_discard"}, self.name)
          if choice == "shenfu_draw" then
            to:drawCards(1, self.name)
          else
            local card = room:askForCardsChosen(player, to, 1, 1, "h", self.name)
            room:throwCard(card, self.name, to, player)
          end
        end
        if to:getHandcardNum() ~= to.hp then
          break
        end
      end
    end
    if not player.dead and n > 0 then
      player:drawCards(math.min(n, 5), self.name)
    end
  end,
}
local joy__qixian = fk.CreateTriggerSkill{
  name = "joy__qixian",
  anim_type = "control",
  events = {fk.EventPhaseEnd},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and not player:isKongcheng()
  end,
  on_cost = function (self, event, target, player, data)
    local card = player.room:askForCard(player, 1, 1, false, self.name, true, ".", "#joy__qixian-card")
    if #card > 0 then
      self.cost_data = card[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player:addToPile(self.name, self.cost_data, false, self.name)
  end,
}
local joy__qixian_delay = fk.CreateTriggerSkill{
  name = "#joy__qixian_delay",
  mute = true,
  events = {fk.TurnEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return target == player and #player:getPile("joy__qixian") > 0
  end,
  on_use = function(self, event, target, player, data)
    local dummy = Fk:cloneCard("slash")
    dummy:addSubcards(player:getPile("joy__qixian"))
    player.room:obtainCard(player, dummy, false, fk.ReasonPrey)
  end,
}
local joy__qixian_maxcards = fk.CreateMaxCardsSkill{
  name = "#joy__qixian_maxcards",
  frequency = Skill.Compulsory,
  fixed_func = function (self, player)
    if player:hasSkill(joy__qixian) then
      return 7
    end
  end,
}
local joy__feifu = fk.CreateViewAsSkill{
  name = "joy__feifu",
  anim_type = "defensive",
  pattern = "jink",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).color == Card.Black
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return end
    local card = Fk:cloneCard("jink")
    card.skillName = self.name
    card:addSubcard(cards[1])
    return card
  end,
}
godzhenji:addSkill(joy__shenfu)
joy__qixian:addRelatedSkill(joy__qixian_maxcards)
joy__qixian:addRelatedSkill(joy__qixian_delay)
godzhenji:addSkill(joy__qixian)
godzhenji:addSkill(joy__feifu)
Fk:loadTranslationTable{
  ["joy__godzhenji"] = "神甄姬",
  ["joy__shenfu"] = "神赋",
  [":joy__shenfu"] = "结束阶段，如果你的手牌数量为：奇数，可对一名其他角色造成1点雷电伤害，若造成其死亡，你可重复此流程；"..
  "偶数，可令一名角色摸一张牌或你弃置其一张手牌，若执行后该角色的手牌数等于其体力值，你可重复此流程（不能对本回合指定过的目标使用）。"..
  "然后你摸X张牌（X为你本回合执行〖神赋〗流程的次数，最大为5）。",
  ["joy__qixian"] = "七弦",
  [":joy__qixian"] = "锁定技，你的手牌上限为7。出牌阶段结束时，你可以将一张手牌移出游戏直到回合结束。",
  ["#joy__qixian_delay"] = "七弦",
  ["#joy__qixian-card"] = "七弦：你可以将一张手牌移出游戏直到回合结束",
  ["joy__feifu"] = "飞凫",
  [":joy__feifu"] = "你可以将一张黑色牌当【闪】使用或打出。",
}

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
      if data.extra_data and data.extra_data.joy__tongli then return end
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
    data.extra_data = data.extra_data or {}
    data.extra_data.joy__tongli = player:getMark("@joy__tongli-turn")
  end,

  refresh_events = {fk.AfterCardUseDeclared, fk.CardUseFinished},
  can_refresh = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) then
      if event == fk.AfterCardUseDeclared then
        return player.phase == Player.Play and not table.contains(data.card.skillNames, self.name)
      else
        return target == player and data.extra_data and data.extra_data.joy__tongli
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    if event == fk.AfterCardUseDeclared then
      room:addPlayerMark(player, "@joy__tongli-turn", 1)
    else
      local n = data.extra_data.joy__tongli
      for i = 1, n, 1 do
        if data.card.name == "amazing_grace" then
          --room.logic:trigger(fk.CardUseFinished, player, data)  玩点枣祗&任峻
          table.forEach(room.players, function(p) room:closeAG(p) end)  --手动五谷
          if data.extra_data and data.extra_data.AGFilled then
            local toDiscard = table.filter(data.extra_data.AGFilled, function(id) return room:getCardArea(id) == Card.Processing end)
            if #toDiscard > 0 then
              room:moveCards({
                ids = toDiscard,
                toArea = Card.DiscardPile,
                moveReason = fk.ReasonPutIntoDiscardPile,
              })
            end
          end
          data.extra_data.AGFilled = nil

          local toDisplay = room:getNCards(#TargetGroup:getRealTargets(data.tos))
          room:moveCards({
            ids = toDisplay,
            toArea = Card.Processing,
            moveReason = fk.ReasonPut,
          })
          table.forEach(room.players, function(p) room:fillAG(p, toDisplay) end)
          data.extra_data = data.extra_data or {}
          data.extra_data.AGFilled = toDisplay
        end
        room:doCardUseEffect(data)
      end
      data.extra_data.joy__tongli = false
    end
  end,
}
local joy__shezang = fk.CreateTriggerSkill{
  name = "joy__shezang",
  anim_type = "drawcard",
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and (target == player or player.phase ~= Player.NotActive) and
      player:usedSkillTimes(self.name, Player.HistoryTurn) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits = {"spade", "club", "heart", "diamond"}
    local cards = {}
    while #suits > 0 do
      local pattern = table.random(suits)
      table.removeOne(suits, pattern)
      table.insertTable(cards, room:getCardsFromPileByRule(".|.|"..pattern))
    end
    if #cards > 0 then
      room:moveCards({
        ids = cards,
        to = player.id,
        toArea = Card.PlayerHand,
        moveReason = fk.ReasonJustMove,
        proposer = player.id,
        skillName = self.name,
      })
    end
  end,
}
zhangxuan:addSkill(joy__tongli)
zhangxuan:addSkill(joy__shezang)
Fk:loadTranslationTable{
  ["joy__zhangxuan"] = "张嫙",
  ["joy__tongli"] = "同礼",
  [":joy__tongli"] = "出牌阶段，当你使用牌指定目标后，若你手牌中的花色数等于你此阶段已使用牌的张数，你可令此牌效果额外执行X次（X为你手牌中的花色数，"..
  "目标发生变化仍生效）。",
  ["joy__shezang"] = "奢葬",
  [":joy__shezang"] = "每回合限一次，当你或你回合内有角色进入濒死状态时，你可以从牌堆获得不同花色的牌各一张。",
  ["@joy__tongli-turn"] = "同礼",
}


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
  events = {fk.TurnStart, fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TurnStart then
      return player == target and player:getMark("@joy_mou__kurou") > 0
    else
      return player == target and player:hasSkill(joy_mou__kurou) and data.card.name == "peach"
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
  [":joy_mou__kurou"] = "出牌阶段限一次，你可以失去一点体力并令体力上限和手牌上限增加1点直到下回合开始。当你使用【桃】后，此技能视为未发动。",
  ["@joy_mou__kurou"] = "苦肉",
  ["#joy_mou__kurou_delay"] = "苦肉",

  ["joy_mou__zhaxiang"] = "诈降",
  [":joy_mou__zhaxiang"] = "锁定技，①每当你失去一点体力后，摸三张牌；②回合结束时，你摸X张牌；③每回合你使用的前X张【杀】无距离和次数限制且无法响应（X为你已损失的体力值的一半，向上取整）。",
  ["@joy_mou__zhaxiang-turn"] = "诈降",
}



local joy__zhugedan = General(extension, "joy__zhugedan", "wei", 4)
local joy__gongao = fk.CreateTriggerSkill{
  name = "joy__gongao",
  anim_type = "support",
  frequency = Skill.Compulsory,
  events = {fk.EnterDying},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target ~= player
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:changeMaxHp(player, 1)
    if not player.dead and player:isWounded() then
      room:recover { num = 1, skillName = self.name, who = player, recoverBy = player}
    end
  end,
}
local joy__juyi = fk.CreateTriggerSkill{
  name = "joy__juyi",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player.maxHp > #player.room.alive_players and player:hasSkill(self) and
     player.phase == Player.Start and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name)
  end,
  on_use = function(self, event, target, player, data)
    local n = player.maxHp - #player.player_cards[Player.Hand]
    if n > 0 then
      player:drawCards(n, self.name)
    end
    player.room:handleAddLoseSkills(player, "joy__benghuai|ty_ex__weizhong")
  end,
}
local joy__benghuai = fk.CreateTriggerSkill{
  name = "joy__benghuai",
  anim_type = "negative",
  frequency = Skill.Compulsory,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self) and player.phase == Player.Finish then
      return table.find(player.room.alive_players, function (p)
        return p.hp < player.hp
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local choice = room:askForChoice(player, {"loseMaxHp", "loseHp"}, self.name)
    if choice == "loseMaxHp" then
      room:changeMaxHp(player, -1)
    else
      room:loseHp(player, 1, self.name)
    end
    if not player.dead then
      player:drawCards(1, self.name)
    end
  end,
}
joy__zhugedan:addSkill(joy__gongao)
joy__zhugedan:addSkill(joy__juyi)
joy__zhugedan:addRelatedSkill(joy__benghuai)
joy__zhugedan:addRelatedSkill("ty_ex__weizhong")
Fk:loadTranslationTable{
  ["joy__zhugedan"] = "诸葛诞",
  ["#joy__zhugedan"] = "薤露蒿里",
  ["joy__gongao"] = "功獒",
  [":joy__gongao"] = "锁定技，每当一名其他角色进入濒死状态时，你增加1点体力上限，然后回复1点体力。",
  ["joy__juyi"] = "举义",
  [":joy__juyi"] = "限定技，准备阶段，若你体力上限大于全场角色数，你可以将手牌摸至体力上限，然后获得技能〖崩坏〗和〖威重〗。",
  -- 可以不发动的觉醒技 村成限定技
  ["joy__benghuai"] = "崩坏",
  [":joy__benghuai"] = "锁定技，结束阶段，若你不是体力值最低的角色，则你失去1点体力或减少1点体力上限，并摸一张牌。",
}


return extension
