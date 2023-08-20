local extension = Package("joy_sp")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_sp"] = "欢乐专属",
  ["joy"] = "欢乐",
  ["joysp"] = "欢乐SP",
}

--几乎全新技能组的武将
--于吉 左慈 甘夫人 SP大乔 SP小乔 SP甄姬 神张辽 神典韦 神孙权 神大小乔 神华佗 神貂蝉

local ganfuren = General(extension, "joy__ganfuren", "shu", 3, 3, General.Female)
local joy__shushen = fk.CreateTriggerSkill{
  name = "joy__shushen",
  anim_type = "support",
  events = {fk.DamageInflicted},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self.name)
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#joy__shushen-invoke::"..target.id)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:loseHp(player, 1, self.name)
    if not player.dead then
      player:drawCards(1, self.name)
      target:drawCards(1, self.name)
    end
    return true
  end,
}
local joy__shushen_trigger = fk.CreateTriggerSkill{
  name = "#joy__shushen_trigger",
  mute = true,
  events = {fk.HpRecover},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("joy__shushen")
  end,
  on_trigger = function(self, event, target, player, data)
    self.cancel_cost = false
    for i = 1, data.num do
      if self.cancel_cost then break end
      self:doCost(event, target, player, data)
    end
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local to = room:askForChoosePlayers(player, table.map(room:getOtherPlayers(player),
      function(p) return p.id end), 1, 1, "#joy__shushen-choose", "joy__shushen", true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
    self.cancel_cost = true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:broadcastSkillInvoke("joy__shushen")
    room:notifySkillInvoked(player, "joy__shushen")
    room:getPlayerById(self.cost_data):drawCards(1, "joy__shushen")
  end,
}
local joy__huangsi = fk.CreateTriggerSkill{
  name = "joy__huangsi",
  anim_type = "support",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, self.name, nil, "#joy__huangsi-invoke")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player:getHandcardNum()
    room:recover({
      who = player,
      num = 1 - player.hp,
      recoverBy = player,
      skillName = self.name
    })
    player:throwAllCards("h")
    if player.dead then return end
    local to = room:askForChoosePlayers(player, table.map(room.alive_players, function(p)
      return p.id end), 1, 1, "#joy__huangsi-choose:::"..(n + 2), self.name, true)
    if #to > 0 then
      room:getPlayerById(to[1]):drawCards(n + 1, self.name)
    end
  end,
}
joy__shushen:addRelatedSkill(joy__shushen_trigger)
ganfuren:addSkill(joy__shushen)
ganfuren:addSkill(joy__huangsi)
Fk:loadTranslationTable{
  ["joy__ganfuren"] = "甘夫人",
  ["joy__shushen"] = "淑慎",
  [":joy__shushen"] = "当一名角色受到伤害时，你可以失去1点体力并防止此伤害，然后你与其各摸一张牌；当你回复1点体力后，你可以令一名其他角色摸一张牌。",
  ["joy__huangsi"] = "皇思",
  [":joy__huangsi"] = "限定技，当你处于濒死状态时，你可以回复体力至1并弃置所有手牌，然后你可以令一名角色摸X+2张牌（X为你弃置的牌数）。",
  ["#joy__shushen-invoke"] = "淑慎：你可以失去1点体力防止 %dest 受到的伤害，然后你与其各摸一张牌",
  ["#joy__shushen-choose"] = "淑慎：你可以令一名其他角色摸一张牌",
  ["#joy__huangsi-invoke"] = "皇思：你可以回复体力至1，弃置所有手牌",
  ["#joy__huangsi-choose"] = "皇思：你可以令一名角色摸%arg张牌",
}

Fk:loadTranslationTable{
  ["joysp__daqiao"] = "大乔",
  ["joy__yanxiao"] = "言笑",
  [":joy__yanxiao"] = "出牌阶段，你可以将一张<font color='red'>♦</font>牌置于一名角色的判定区内，判定区有“言笑”牌的角色下个判定阶段开始时，"..
  "获得其判定区内所有牌并进行一次判定，若结果为：红色，其摸一张牌；黑色，本回合出牌阶段使用【杀】次数上限+1。",
  ["joy__guose"] = "国色",
  [":joy__guose"] = "锁定技，当你失去一张<font color='red'>♦</font>牌后，你摸一张牌。",
  ["joy__anxian"] = "安娴",
  [":joy__anxian"] = "当你不以此法使用【杀】指定目标时，你可以令目标弃置一张手牌；当你成为【杀】的目标时，你可以弃置一张牌令之无效，然后使用者"..
  "摸一张牌，若你弃置的是<font color='red'>♦</font>牌，你视为对其使用一张【杀】。",
}

Fk:loadTranslationTable{
  ["joysp__xiaoqiao"] = "小乔",
  ["joy__xingwu"] = "星舞",
  [":joy__xingwu"] = "出牌阶段限一次，你可以弃置一张手牌并翻面，弃置一名其他角色装备区内一张牌，然后对其造成1点伤害；若其为男性角色，则改为2点。",
  ["joy__luoyan"] = "落雁",
  [":joy__luoyan"] = "锁定技，当你发动〖星舞〗后，直到你下个出牌阶段开始时，你获得〖天香〗和〖红颜〗。",
  ["joy__huimou"] = "回眸",
  [":joy__huimou"] = "当你于回合外使用或打出<font color='red'>♥</font>牌后，或当你发动〖天香〗时，你可以令一名武将牌背面朝上的角色翻至正面。",
}

local sp__zhenji = General(extension, "joysp__zhenji", "qun", 3, 3, General.Female)
local joy__jinghong = fk.CreateTriggerSkill{
  name = "joy__jinghong",
  anim_type = "control",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self.name) and player.phase == Player.Start and
      table.find(player.room:getOtherPlayers(player), function(p) return not p:isKongcheng() end)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isKongcheng() end), function(p) return p.id end)
    local n = math.min(#room.alive_players - 1, 4)
    local tos = room:askForChoosePlayers(player, targets, 1, n, "#joy__jinghong-choose:::"..n, self.name, true)
    if #tos > 0 then
      self.cost_data = tos
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(self.cost_data) do
      if player.dead then return end
      local p = room:getPlayerById(id)
      if not p.dead and not p:isKongcheng() then
        local card = table.random(p:getCardIds("h"))
        p:showCards(card)
        if Fk:getCardById(card).color == Card.Black and (room:getCardOwner(card) == p or room:getCardArea(card) == Card.DiscardPile) then
          room:obtainCard(player, card, true, fk.ReasonPrey)
          if room:getCardOwner(card) == player and room:getCardArea(card) == Card.PlayerHand then
            room:setCardMark(Fk:getCardById(card), "@@joy__jinghong-inhand", 1)
          end
        elseif Fk:getCardById(card).color == Card.Red and room:getCardOwner(card) == p and room:getCardArea(card) == Card.PlayerHand then
          room:throwCard({card}, self.name, p, p)
        end
      end
    end
  end,

  refresh_events = {fk.TurnEnd},
  can_refresh = function(self, event, target, player, data)
    return target == player and player:usedSkillTimes(self.name, Player.HistoryTurn) > 0
  end,
  on_refresh = function(self, event, target, player, data)
    local room = player.room
    for _, id in ipairs(player:getCardIds("h")) do
      room:setCardMark(Fk:getCardById(id), "@@joy__jinghong-inhand", 0)
    end
  end,
}
local joy__jinghong_maxcards = fk.CreateMaxCardsSkill{
  name = "#joy__jinghong_maxcards",
  exclude_from = function(self, player, card)
    return card:getMark("@@joy__jinghong-inhand") > 0
  end,
}
local joy__luoshen = fk.CreateViewAsSkill{
  name = "joy__luoshen",
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
local nya__luoshen_trigger = fk.CreateTriggerSkill{
  name = "#nya__luoshen_trigger",
  mute = true,
  events = {fk.CardUsing, fk.CardResponding},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill("joy__luoshen") and table.contains(data.card.skillNames, "joy__luoshen") and
      player:usedSkillTimes(self.name, Player.HistoryRound) == 0
  end,
  on_cost = function(self, event, target, player, data)
    return player.room:askForSkillInvoke(player, "joy__luoshen")
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local cards = {}
    while true do
      local judge = {
        who = player,
        reason = "joy__luoshen",
        pattern = ".|.|spade,club",
        skipDrop = true,
      }
      room:judge(judge)
      table.insert(cards, judge.card)
      if judge.card.color ~= Card.Black or not room:askForSkillInvoke(player, "joy__luoshen") then
        break
      end
    end
    cards = table.filter(cards, function(card) return room:getCardArea(card.id) == Card.Processing end)
    if #cards == 0 then return end
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(table.map(cards, function(card) return card:getEffectiveId() end))
    room:obtainCard(player.id, dummy, true, fk.ReasonJustMove)
  end,
}
joy__jinghong:addRelatedSkill(joy__jinghong_maxcards)
joy__luoshen:addRelatedSkill(nya__luoshen_trigger)
sp__zhenji:addSkill(joy__jinghong)
sp__zhenji:addSkill(joy__luoshen)
Fk:loadTranslationTable{
  ["joysp__zhenji"] = "甄姬",
  ["joy__jinghong"] = "惊鸿",
  [":joy__jinghong"] = "准备阶段，你可以选择至多X名其他角色（X为存活角色数-1，至多为4），依次随机展示其一张手牌，若为：黑色，你获得之，"..
  "且本回合不计入手牌上限；红色，其弃置之。",
  ["joy__luoshen"] = "洛神",
  [":joy__luoshen"] = "你可以将一张黑色牌当【闪】使用或打出；每轮限一次，你以此法使用或打出【闪】时，你可以判定，若结果为：黑色，你获得之，"..
  "然后你可以重复此流程；红色，你获得之。",
  ["#joy__jinghong-choose"] = "惊鸿：令至多%arg名其他角色依次随机展示一张手牌，若为黑色你获得之，若为红色其弃置之",
  ["@@joy__jinghong-inhand"] = "惊鸿",
}

local goddiaochan = General(extension, "joy__goddiaochan", "god", 3, 3, General.Female)
local joy__meihun = fk.CreateTriggerSkill{
  name = "joy__meihun",
  anim_type = "control",
  events = {fk.EventPhaseStart, fk.TargetConfirmed},
  can_trigger = function(self, event, target, player, data)
    if target == player and player:hasSkill(self.name) then
      if event == fk.EventPhaseStart then
        return player.phase == Player.Finish
      elseif event == fk.TargetConfirmed then
        return data.card.trueName == "slash" and player:getMark("joy__meihun-turn") == 0
      end
    end
  end,
  on_trigger = function(self, event, target, player, data)
    if event == fk.TargetConfirmed then
      player.room:setPlayerMark(player, "joy__meihun-turn", 1)
    end
    self:doCost(event, target, player, data)
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local targets = table.map(table.filter(room:getOtherPlayers(player), function(p)
      return not p:isNude() end), function(p) return p.id end)
    if #targets == 0 then return end
    local to = room:askForChoosePlayers(player, targets, 1, 1, "#joy__meihun-choose", self.name, true)
    if #to > 0 then
      self.cost_data = to[1]
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data)
    local suits = {"spade", "heart", "club", "diamond"}
    local choices = table.map(suits, function(s) return Fk:translate("log_"..s) end)
    local choice = room:askForChoice(player, choices, self.name, "#joy__meihun-choice::"..to.id)
    local suit = suits[table.indexOf(choices, choice)]
    local dummy = Fk:cloneCard("dilu")
    for _, id in ipairs(to:getCardIds("he")) do
      if Fk:getCardById(id):getSuitString() == suit then
        dummy:addSubcard(id)
      end
    end
    if #dummy.subcards > 0 then
      room:obtainCard(player, dummy, false, fk.ReasonGive)
    elseif not to:isKongcheng() then
      local cards = table.simpleClone(to:getCardIds("h"))
      room:fillAG(player, cards)
      local id = room:askForAG(player, cards, false, self.name)
      room:closeAG(player)
      if not id then return false end
      room:obtainCard(player, id, false, fk.ReasonPrey)
    end
  end,
}
local joy__huoxin = fk.CreateActiveSkill{
  name = "joy__huoxin",
  anim_type = "control",
  card_num = 1,
  target_num = 2,
  prompt = "#joy__huoxin",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    if #selected < 2 and #selected_cards == 1 and not Fk:currentRoom():getPlayerById(to_select):isKongcheng() then
      if to_select == Self.id then
        if Fk:currentRoom():getCardArea(selected_cards[1]) == Player.Hand then
          return Self:getHandcardNum() > 1
        else
          return not Self:isKongcheng()
        end
      else
        return true
      end
    end
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    local targets = table.map(effect.tos, function(id) return room:getPlayerById(id) end)
    local pindian = targets[1]:pindian({targets[2]}, self.name)
    if player.dead then return end
    local losers = {}
    if pindian.results[targets[2].id].winner == targets[1] then
      losers = {targets[2]}
    elseif pindian.results[targets[2].id].winner == targets[2] then
      losers = {targets[1]}
    else
      losers = targets
    end
    local suits = {"", "spade", "heart", "club", "diamond"}
    local choices = table.map(suits, function(s) return Fk:translate("log_"..s) end)
    choices[1] = "Cancel"
    local choice = room:askForChoice(player, choices, self.name, "#joy__huoxin-choice")
    if choice ~= "Cancel" then
      local suit = suits[table.indexOf(choices, choice)]
      for _, p in ipairs(losers) do
        if player.dead then return end
        if not p.dead then
          room:doIndicate(player.id, {p.id})
          if table.find(p:getCardIds("he"), function(id) return Fk:getCardById(id):getSuitString() == suit end) then
            local choice2 = room:askForChoice(player, {"joy__huoxin_prey:::"..choice, "joy__huoxin_mark"}, self.name,
              "#joy__huoxin2-choice::"..p.id)
            if choice2[13] == "p" then
              local dummy = Fk:cloneCard("dilu")
              for _, id in ipairs(p:getCardIds("he")) do
                if Fk:getCardById(id):getSuitString() == suit then
                  dummy:addSubcard(id)
                end
              end
              if #dummy.subcards > 0 then
                room:obtainCard(player, dummy, false, fk.ReasonGive)
              end
            else
              room:setPlayerMark(p, "@joy__huoxin-turn", choice)
            end
          else
            room:setPlayerMark(p, "@joy__huoxin-turn", choice)
          end
        end
      end
    end
  end,
}
local joy__huoxin_prohibit = fk.CreateProhibitSkill{
  name = "#joy__huoxin_prohibit",
  prohibit_use = function(self, player, card)
    return player:getMark("@joy__huoxin-turn") ~= 0 and player:getMark("@joy__huoxin-turn") == card:getSuitString(true)
  end,
  prohibit_response = function(self, player, card)
    return player:getMark("@joy__huoxin-turn") ~= 0 and player:getMark("@joy__huoxin-turn") == card:getSuitString(true)
  end,
}
joy__huoxin:addRelatedSkill(joy__huoxin_prohibit)
goddiaochan:addSkill(joy__meihun)
goddiaochan:addSkill(joy__huoxin)
Fk:loadTranslationTable{
  ["joy__goddiaochan"] = "神貂蝉",
  ["joy__meihun"] = "魅魂",
  [":joy__meihun"] = "结束阶段或每回合你首次成为【杀】的目标后，你可以声明一种花色，令一名其他角色交给你所有此花色的牌，若其没有，则你观看"..
  "其手牌并获得其中一张。",
  ["joy__huoxin"] = "惑心",
  [":joy__huoxin"] = "出牌阶段限一次，你可以弃置一张牌令两名角色拼点，然后你可以声明一种花色，令没赢的角色交给你此花色的所有牌"..
  "或获得此花色的“魅惑”标记。有“魅惑”的角色不能使用或打出对应花色的牌直到回合结束。",
  ["#joy__meihun-choose"] = "魅魂：你可以令一名其他角色交给你指定花色的所有牌，或你观看并获得其一张手牌",
  ["#joy__meihun-choice"] = "魅魂：选择令 %dest 交给你的花色",
  ["#joy__huoxin"] = "惑心：弃置一张牌令两名角色拼点，没赢的角色交给你声明花色的牌或获得“魅惑”标记",
  ["#joy__huoxin-choice"] = "惑心：你可以声明一种花色，令没赢的角色交给你此花色的牌或获得“魅惑”标记",
  ["#joy__huoxin2-choice"] = "惑心：选择对 %dest 执行的一项",
  ["joy__huoxin_prey"] = "令其交给你所有%arg牌",
  ["joy__huoxin_mark"] = "令其获得“魅惑”标记",
  ["@joy__huoxin-turn"] = "魅惑",
}

Fk:loadTranslationTable{
  ["joy__libai"] = "李白",
  ["joy__shixian"] = "诗仙",
  [":joy__shixian"] = "锁定技，回合开始时，你清除已有的诗篇并亮出牌堆顶四张牌，根据花色创作对应的诗篇：<font color='red'>♥</font>《静夜思》；"..
  "<font color='red'>♦</font>《行路难》；♠《侠客行》；♣《将进酒》。然后你获得其中重复花色的牌。",
  ["jingyesi"] = "静夜思",
  [":jingyesi"] = "出牌阶段结束时，你可以观看牌堆顶一张牌，然后可以使用此牌；弃牌阶段结束时，你获得牌堆底的一张牌。",
  ["xinglunan"] = "行路难",
  [":xinglunan"] = "锁定技，你的回合外，当其他角色对你使用的【杀】结算后，直到你的回合开始，其他角色计算与你的距离+1。",
  ["xiakexing"] = "侠客行",
  [":xiakexing"] = "当你使用了牌名中有“剑”的武器时，你视为使用一张【万箭齐发】；当你使用【杀】造成伤害后，若你装备了武器，"..
  "你可以与其拼点：若你赢，其减1点体力上限；若你没赢，则弃置你装备区内的武器。",
  ["qiangjinjiu"] = "将进酒",
  [":qiangjinjiu"] = "其他角色回合开始时，你可以弃置一张手牌并选择一项：1.弃置其装备区内所有的装备，令其从牌堆中获得一张【酒】；"..
  "2.获得其手牌中所有【酒】，若其手牌中没有【酒】，则改为获得其一张牌。",
}

return extension
