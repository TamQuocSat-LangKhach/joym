local extension = Package("joy_yj")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_yj"] = "欢乐-一将成名",
}

--曹植 于禁 荀攸 曹彰 步练师 刘封 伏皇后 周仓 曹休 孙登 徐氏 曹节
local yujin = General(extension, "joy__yujin", "wei", 4)
local yizhong = fk.CreateTriggerSkill{
  name = "joy__yizhong",
  anim_type = "defensive",
  frequency = Skill.Compulsory,
  events = {fk.PreCardEffect},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and data.card.trueName == "slash" and player.id == data.to and
      data.card.suit == Card.Club and #player.player_cards[Player.Equip] == 0
  end,
  on_use = Util.TrueFunc,
}
yujin:addSkill(yizhong)
yujin:addSkill("ty_ex__zhenjun")
Fk:loadTranslationTable{
  ["joy__yujin"] = "于禁",
  ["joy__yizhong"] = "毅重",
  [":joy__yizhong"] = "锁定技，若你的装备区没有牌，梅花【杀】对你无效。",
}

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

local sundeng = General(extension, "joy__sundeng", "wu", 4)
local joy__kuangbi = fk.CreateActiveSkill{
  name = "joy__kuangbi",
  anim_type = "control",
  card_num = 0,
  target_num = 1,
  prompt = "#joy__kuangbi",
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0
  end,
  card_filter = function(self, to_select, selected)
    return false
  end,
  target_filter = function(self, to_select, selected, selected_cards)
    return #selected == 0 and to_select ~= Self.id and not Fk:currentRoom():getPlayerById(to_select):isNude()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local target = room:getPlayerById(effect.tos[1])
    local cards = room:askForCard(target, 1, 3, true, self.name, false, ".", "#joy__kuangbi-card:"..player.id)
    local dummy = Fk:cloneCard("dilu")
    dummy:addSubcards(cards)
    player:addToPile(self.name, dummy, false, self.name)
    if player.dead or target.dead then return end
    if room:askForSkillInvoke(player, self.name, nil, "#joy__kuangbi-draw::"..target.id..":"..#dummy.subcards) then
      target:drawCards(#dummy.subcards, self.name)
    end
  end,
}
local joy__kuangbi_trigger = fk.CreateTriggerSkill {
  name = "#joy__kuangbi_trigger",
  mute = true,
  events = {fk.TurnStart, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if event == fk.TurnStart then
      return target == player and #player:getPile("joy__kuangbi") > 0
    elseif player:hasSkill("joy__kuangbi") and (table.every(player:getCardIds("h"), function(id)
      return Fk:getCardById(id):getMark("@@joy__kuangbi") == 0 end)) then
      for _, move in ipairs(data) do
        if move.from == player.id and move.extra_data and move.extra_data.joy__kuangbi then
          return true
        end
      end
    end
  end,
  on_cost = function(self, event, target, player, data)
    return true
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    player:broadcastSkillInvoke("joy__kuangbi")
    room:notifySkillInvoked(player, "joy__kuangbi", "support")
    if event == fk.TurnStart then
      local dummy = Fk:cloneCard("dilu")
      dummy:addSubcards(player:getPile("joy__kuangbi"))
      for _, id in ipairs(player:getPile("joy__kuangbi")) do
        room:setCardMark(Fk:getCardById(id), "@@joy__kuangbi", 1)
      end
      room:obtainCard(player, dummy, false, fk.ReasonJustMove)
    else
      player:drawCards(1, "joy__kuangbi")
      if player:isWounded() and not player.dead then
        room:recover{
          who = player,
          num = 1,
          recoverBy = player,
          skillName = "joy__kuangbi",
        }
      end
    end
  end,

  refresh_events = {fk.BeforeCardsMove},
  can_refresh = function(self, event, target, player, data)
    if player:hasSkill("joy__kuangbi") then
      for _, move in ipairs(data) do
        if move.from == player.id then
          for _, info in ipairs(move.moveInfo) do
            if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@joy__kuangbi") > 0 then
              return true
            end
          end
        end
      end
    end
  end,
  on_refresh = function(self, event, target, player, data)
    for _, move in ipairs(data) do
      if move.from == player.id then
        local yes = false
        for _, info in ipairs(move.moveInfo) do
          if info.fromArea == Card.PlayerHand and Fk:getCardById(info.cardId):getMark("@@joy__kuangbi") > 0 then
            player.room:setCardMark(Fk:getCardById(info.cardId), "@@joy__kuangbi", 0)
            yes = true
          end
        end
        if yes then
          move.extra_data = move.extra_data or {}
          move.extra_data.joy__kuangbi = true
        end
      end
    end
  end,
}
joy__kuangbi:addRelatedSkill(joy__kuangbi_trigger)
sundeng:addSkill(joy__kuangbi)
Fk:loadTranslationTable{
  ["joy__sundeng"] = "孙登",
  ["joy__kuangbi"] = "匡弼",
  [":joy__kuangbi"] = "出牌阶段限一次，你可以令一名其他角色将其一至三张牌置于你的武将牌上，然后你可令其摸等量的牌。你的回合开始时，"..
  "你获得武将牌上的所有牌。当你失去手牌中最后一张“匡弼”牌时，你摸一张牌并回复1点体力。",
  ["#joy__kuangbi"] = "匡弼：令一名角色将至多三张牌置为“匡弼”牌，你可以令其摸等量牌，你回合开始时获得“匡弼”牌",
  ["#joy__kuangbi-card"] = "匡弼：将至多三张牌置为 %src 的“匡弼”牌",
  ["#joy__kuangbi-draw"] = "匡弼：是否令 %dest 摸%arg张牌？",
  ["@@joy__kuangbi"] = "匡弼",
}

local joy__guanping = General(extension, "joy__guanping", "shu", 4)
local joy__longyin = fk.CreateTriggerSkill{
  name = "joy__longyin",
  anim_type = "support",
  events = {fk.CardUsing},
  can_trigger = function(self, event, target, player, data)
    return player:hasSkill(self) and target.phase == Player.Play and data.card.trueName == "slash" and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local cards = player.room:askForDiscard(player, 1, 1, true, self.name, true, ".", "#joy__longyin-invoke::"..target.id, true)
    if #cards > 0 then
      self.cost_data = cards
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    player.room:throwCard(self.cost_data, self.name, player, player)
    if not data.extraUse then
      data.extraUse = true
      target:addCardUseHistory(data.card.trueName, -1)
    end
    if data.card.color == Card.Red and not player.dead then
      player:drawCards(1, self.name)
    end
    if data.card.suit == Fk:getCardById(self.cost_data[1]).suit and player:usedSkillTimes("joy__jiezhong", Player.HistoryGame) > 0 then
      player:setSkillUseHistory("joy__jiezhong", 0, Player.HistoryGame)
    end
  end,
}
local joy__jiezhong = fk.CreateTriggerSkill{
  name = "joy__jiezhong",
  anim_type = "drawcard",
  frequency = Skill.Limited,
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.phase == Player.Play and
      player.maxHp > player:getHandcardNum() and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_cost = function(self, event, target, player, data)
    local draw = player.maxHp - player:getHandcardNum()
    return player.room:askForSkillInvoke(player, self.name, nil, "#joy__jiezhong-invoke:::"..draw)
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local n = player.maxHp - player:getHandcardNum()
    player:drawCards(n, self.name)
  end,
}
joy__guanping:addSkill(joy__longyin)
joy__guanping:addSkill(joy__jiezhong)
Fk:loadTranslationTable{
  ["joy__guanping"] = "关平",
  ["#joy__guanping"] = "忠臣孝子",

  ["joy__longyin"] = "龙吟",
  [":joy__longyin"] = "每当一名角色在其出牌阶段使用【杀】时，你可以弃置一张牌令此【杀】不计入出牌阶段使用次数，若此【杀】为红色，你摸一张牌。"..
  "若你以此法弃置的牌花色与此【杀】相同，你重置〖竭忠〗。",
  ["#joy__longyin-invoke"] = "龙吟：你可以弃置一张牌令 %dest 的【杀】不计入次数限制",
  ["joy__jiezhong"] = "竭忠",
  [":joy__jiezhong"] = "限定技，出牌阶段开始时，若你的手牌数小于体力上限，你可以将手牌补至体力上限。",
  ["#joy__jiezhong-invoke"] = "竭忠：是否发动“竭忠”摸%arg张牌？ ",

}

local joy__xushu = General(extension, "joy__xushu", "shu", 3)
local joy__jujian = fk.CreateTriggerSkill{
  name = "joy__jujian",
  anim_type = "support",
  events = {fk.EventPhaseStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (player.phase == Player.Finish or player.phase == Player.Start)and not player:isNude()
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local tos, id = player.room:askForChooseCardAndPlayers(player, table.map(room.alive_players, Util.IdMapper), 1, 1, ".|.|.|.|.|^basic", "#joy__jujian-choose", self.name, true)
    if #tos > 0 then
      self.cost_data = {tos[1], id}
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(self.cost_data[1])
    room:throwCard({self.cost_data[2]}, self.name, player, player)
    local choices = {"draw2"}
    if to:isWounded() then
      table.insert(choices, "recover")
    end
    if not to.faceup or to.chained then
      table.insert(choices, "joy__jujian_reset")
    end
    local choice = room:askForChoice(to, choices, self.name, nil, false, {"draw2", "recover", "joy__jujian_reset"})
    if choice == "draw2" then
      to:drawCards(2, self.name)
    elseif choice == "recover" then
      room:recover({
        who = to,
        num = 1,
        recoverBy = player,
        skillName = self.name
      })
    else
      to:reset()
    end
  end,
}
joy__xushu:addSkill("wuyan")
joy__xushu:addSkill(joy__jujian)
Fk:loadTranslationTable{
  ["joy__xushu"] = "徐庶",
  ["#joy__xushu"] = "忠孝的侠士",

  ["joy__jujian"] = "举荐",
  [":joy__jujian"] = "准备或结束阶段，你可以弃置一张非基本牌，令一名角色选择一项：摸两张牌；回复1点体力；复原武将牌。",
  ["#joy__jujian-choose"] = "举荐：你可以弃置一张非基本牌，令一名角色选择摸俩张牌/回复体力/复原武将牌",
  ["joy__jujian_reset"] = "复原武将牌",

}

local joyex__liaohua = General(extension, "joyex__liaohua", "shu", 4)
local joyex__dangxian = fk.CreateTriggerSkill{
  name = "joyex__dangxian",
  anim_type = "offensive",
  events = {fk.TurnStart},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self)
  end,
  on_use = function(self, event, target, player, data)
    local cards = player.room:getCardsFromPileByRule("slash", 1)
    if #cards > 0 then
      player.room:obtainCard(player, cards[1], true, fk.ReasonJustMove)
    end
    player:gainAnExtraPhase(Player.Play)
  end,
}
local joyex__fuli = fk.CreateTriggerSkill{
  name = "joyex__fuli",
  anim_type = "defensive",
  frequency = Skill.Limited,
  events = {fk.AskForPeaches},
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and player.dying and player:usedSkillTimes(self.name, Player.HistoryGame) == 0
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:setPlayerMark(player, self.name, 1)
    local kingdoms = {}
    for _, p in ipairs(room:getAlivePlayers()) do
      table.insertIfNeed(kingdoms, p.kingdom)
    end
    room:recover({
      who = player,
      num = math.min(#kingdoms, player.maxHp) - player.hp,
      recoverBy = player,
      skillName = self.name
    })
    if player:getHandcardNum() < #kingdoms and not player.dead then
      player:drawCards(#kingdoms - player:getHandcardNum())
    end
    if #kingdoms > 3 and not player.dead then
      player:turnOver()
    end
  end,
}
joyex__liaohua:addSkill(joyex__dangxian)
joyex__liaohua:addSkill(joyex__fuli)
Fk:loadTranslationTable{
  ["joyex__liaohua"] = "界廖化",
  ["#joyex__liaohua"] = "历尽沧桑",

  ["joyex__dangxian"] = "当先",
  [":joyex__dangxian"] = "回合开始时你进行一个额外的出牌阶段并摸一张【杀】。",
  ["joyex__fuli"] = "伏枥",
  [":joyex__fuli"] = "限定技，当你处于濒死状态时，你可以将体力回复至X点且手牌摸至X张（X为全场势力数）"..
  "若X大于3，你翻面。",

}

local caoxiu = General(extension, "joy__caoxiu", "wei", 4)
local joy__qingxi = fk.CreateTriggerSkill{
  name = "joy__qingxi",
  events = {fk.TargetSpecified},
  anim_type = "offensive",
  can_trigger = function(self, event, target, player, data)
    return target == player and player:hasSkill(self) and (data.card.trueName == "slash" or data.card.trueName == "duel")
  end,
  on_cost = function(self, event, target, player, data)
    local room = player.room
    local n = 0
    for _, p in ipairs(room.alive_players) do
      if player:inMyAttackRange(p) then
        n = n + 1
      end
    end
    local max_num = #player:getEquipments(Card.SubtypeWeapon) > 0 and 4 or 2
    n = math.min(n, max_num)
    if player.room:askForSkillInvoke(player, self.name, data, "#joy__qingxi::" .. data.to..":"..n) then
      self.cost_data = n
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local to = room:getPlayerById(data.to)
    local num = self.cost_data
    if #room:askForDiscard(to, num, num, false, self.name, true, ".", "#joy__qingxi-discard:::"..num) == num then
      local weapon = player:getEquipments(Card.SubtypeWeapon)
      if #weapon > 0 then
        room:throwCard(weapon, self.name, player, to)
      end
    else
      data.extra_data = data.extra_data or {}
      data.extra_data.ty_ex__qingxi = data.to
      local judge = {
        who = player,
        reason = self.name,
        pattern = ".|.|club,spade,heart,diamond",
      }
      room:judge(judge)
      if judge.card.color == Card.Red then
        data.disresponsive = true
      elseif judge.card.color == Card.Black and not player.dead then
        player:drawCards(2,self.name)
      end
    end
  end,
}
local joy__qingxi_delay = fk.CreateTriggerSkill{
  name = "#joy__qingxi_delay",
  events = {fk.DamageCaused},
  mute = true,
  can_trigger = function(self, event, target, player, data)
    if target == player then
      local e = player.room.logic:getCurrentEvent():findParent(GameEvent.CardEffect)
      if e then
        local use = e.data[1]
        if use.extra_data and use.extra_data.ty_ex__qingxi == data.to.id then
          return true
        end
      end
    end
  end,
  on_cost = Util.TrueFunc,
  on_use = function(self, event, target, player, data)
    data.damage = data.damage + 1
  end,
}
joy__qingxi:addRelatedSkill(joy__qingxi_delay)
caoxiu:addSkill("qianju")
caoxiu:addSkill(joy__qingxi)
Fk:loadTranslationTable{
  ["joy__caoxiu"] = "界曹休",
  ["#joy__caoxiu"] = "千里骐骥",

  ["joy__qingxi"] = "倾袭",
  [":joy__qingxi"] = "当你使用【杀】或【决斗】指定一名角色为目标后，你可以令其选择一项："..
  "1.弃置等同于你攻击范围内的角色数张手牌（至多为2，若你武器区里有武器牌则改为至多为4），然后弃置你装备区里的武器牌；"..
  "2.令此牌对其造成的基础伤害值+1且你进行一次判定，若结果为红色，该角色不能响应此牌;若结果为黑色，你摸两张牌",
  ["#joy__qingxi"] = "倾袭：可令 %dest 选一项：1.弃 %arg 张手牌并弃置你的武器；2.伤害+1且你判定，为红不能响应，为黑摸两张牌",
  ["#joy__qingxi-discard"] = "倾袭：你需弃置 %arg 张手牌，否则伤害+1且其判定，结果为红你不能响应,结果为黑其摸两张牌",

}

return extension
