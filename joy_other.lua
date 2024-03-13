local extension = Package("joy_other")
extension.extensionName = "joym"

Fk:loadTranslationTable{
  ["joy_other"] = "欢乐-其他",
}

local U = require "packages/utility/utility"

-- 限时地主武将，以及难以分类的武将






Fk:loadTranslationTable{
  ["joy__libai"] = "李白",
  ["joy__shixian"] = "诗仙",
  [":joy__shixian"] = "锁定技，准备阶段，你清除已有的诗篇并亮出牌堆顶四张牌，根据花色创作对应的诗篇：<font color='red'>♥</font>《静夜思》；"..
  "<font color='red'>♦</font>《行路难》；♠《侠客行》；♣《将进酒》。然后你获得其中重复花色的牌。",
  ["jingyesi"] = "静夜思",
  [":jingyesi"] = "出牌阶段结束时，你可以观看牌堆顶一张牌，然后可以使用此牌；弃牌阶段结束时，你获得牌堆底的一张牌。",
  ["xinglunan"] = "行路难",
  [":xinglunan"] = "锁定技，你的回合外，当其他角色对你使用【杀】结算后，直到你的回合开始，其他角色计算与你的距离+1。",
  ["xiakexing"] = "侠客行",
  [":xiakexing"] = "当你使用牌名中有“剑”的武器时，你视为使用一张【万箭齐发】；当你使用【杀】造成伤害后，若你装备了武器，你可以与其拼点："..
  "若你赢，其减1点体力上限；若你没赢，则弃置你装备区内的武器。",
  ["qiangjinjiu"] = "将进酒",
  [":qiangjinjiu"] = "其他角色准备阶段，你可以弃置一张手牌并选择一项：1.弃置其装备区内所有的装备，令其从牌堆中获得一张【酒】；"..
  "2.获得其手牌中所有【酒】，若其手牌中没有【酒】，则改为获得其一张牌。",
}

local joy__change = General(extension, "joy__change", "god", 1, 4, General.Female)
local joy__daoyao = fk.CreateActiveSkill{
  name = "joy__daoyao",
  anim_type = "drawcard",
  card_num = 1,
  target_num = 0,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:currentRoom():getCardArea(to_select) ~= Player.Equip and
      not Self:prohibitDiscard(Fk:getCardById(to_select))
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    room:throwCard(effect.cards, self.name, player, player)
    if player.dead then return end
    local ids = room:getCardsFromPileByRule("peach")
    if #ids > 0 then
      room:obtainCard(player, ids[1], false, fk.ReasonPrey)
    end
    if not player.dead then
      player:drawCards(3 - #ids, self.name)
    end
  end,
}
joy__change:addSkill(joy__daoyao)
local joy__benyue = fk.CreateTriggerSkill{
  name = "joy__benyue",
  frequency = Skill.Wake,
  events = {fk.HpRecover, fk.AfterCardsMove},
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) and player:usedSkillTimes(self.name, Player.HistoryGame) == 0 then
      if event == fk.HpRecover then
        return target == player
      else
        for _, move in ipairs(data) do
          if move.to == player.id and move.toArea == Card.PlayerHand then
            for _, info in ipairs(move.moveInfo) do
              if info.fromArea == Card.DrawPile and Fk:getCardById(info.cardId).name == "peach" then
                return true
              end
            end
          end
        end
      end
    end
  end,
  can_wake = function(self, event, target, player, data)
    if event == fk.HpRecover then
      local n = 0
      player.room.logic:getEventsOfScope(GameEvent.ChangeHp, 1, function(e)
        local damage = e.data[1]
        if e.data[1] == player and e.data[3] == "recover" then
          n = n + e.data[2]
        end
      end, Player.HistoryGame)
      return n > 2
    else
      return #table.filter(player:getCardIds("h"), function (id)
        return Fk:getCardById(id).name == "peach"
      end) > 2
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if player.maxHp < 15 then
      room:changeMaxHp(player, 15-player.maxHp)
    end
    room:handleAddLoseSkills(player, "joy__guanghan")
  end,
}
joy__change:addSkill(joy__benyue)
local joy__guanghan = fk.CreateTriggerSkill{
  name = "joy__guanghan",
  anim_type = "offensive",
  events = {fk.Damaged},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      return data.extra_data and table.find(data.extra_data.joy__guanghan or {}, function (pid)
        return pid ~= player.id and not player.room:getPlayerById(pid).dead
      end)
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    for _, pid in ipairs(data.extra_data.joy__guanghan) do
      local p = room:getPlayerById(pid)
      if pid ~= player.id and not p.dead then
        if p:isKongcheng() or #room:askForDiscard(p, 1, 1, false, self.name, true, ".", "#joy__guanghan-discard:::"..data.damage) == 0 then
          room:loseHp(p, data.damage, self.name)
        end
      end
    end
  end,

  refresh_events = {fk.BeforeHpChanged},
  can_refresh = function(self, event, target, player, data)
    return data.damageEvent and target == player
  end,
  on_refresh = function(self, event, target, player, data)
    local damage = data.damageEvent
    damage.extra_data = damage.extra_data or {}
    local list = {}
    for _, p in ipairs(player.room:getAlivePlayers()) do
      if target:getNextAlive() == p or p:getNextAlive() == target then
        table.insertIfNeed(list, p.id)
      end
    end
    damage.extra_data.joy__guanghan = list
  end,
}
joy__change:addRelatedSkill(joy__guanghan)
Fk:loadTranslationTable{
  ["joy__change"] = "嫦娥",
  ["#joy__change"] = "广寒仙子",
  
  ["joy__daoyao"] = "捣药",
  [":joy__daoyao"] = "出牌阶段限一次，你可以弃置一张手牌，从牌堆获得一张【桃】并摸两张牌，若牌堆没有【桃】，改为摸三张牌。",

  ["joy__benyue"] = "奔月",
  [":joy__benyue"] = "觉醒技，当你摸到【桃】后若你有至少三张【桃】，或你累计回复3点体力后，你将体力上限增加至15，并获得技能〖广寒〗。",

  ["joy__guanghan"] = "广寒",
  [":joy__guanghan"] = "锁定技，当一名角色受到伤害后，与其相邻的其他角色需弃置一张手牌，否则失去等量体力。",
  ["#joy__guanghan-discard"] = "广寒：你需弃置一张手牌，否则失去 %arg 点体力",

  ["$joy__daoyao1"] = "入河蟾不没，捣药兔长生！",
  ["$joy__daoyao2"] = "转空轧軏冰轮响，捣药叮当玉杵鸣！",
  ["$joy__benyue1"] = "一入月宫去，千秋闭峨眉。",
  ["$joy__benyue2"] = "纵令奔月成仙去，且作行云入梦来。",
  ["$joy__guanghan1"] = "银河无声月宫冷，思念如影伴孤灯。",
  ["$joy__guanghan2"] = "月宫清冷人独立，寒梦纷飞思绪深。",
}

local joy__nvwa = General(extension, "joy__nvwa", "god", 69, 159, General.Female)
local joy__butian = fk.CreateTriggerSkill{
  name = "joy__butian",
  frequency = Skill.Compulsory,
  events = { fk.DamageCaused , fk.DamageInflicted, fk.RoundEnd, fk.HpChanged, fk.MaxHpChanged, fk.GameStart, fk.EventAcquireSkill},
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return false end
    if event == fk.DamageCaused then
      return player:getLostHp() > 4 and target == player and data.to ~= player
    elseif event == fk.DamageInflicted then
      return player:getLostHp() > 4 and target == player
    elseif event == fk.RoundEnd then
      return player:getLostHp() > 4
    elseif player.maxHp == player.hp then
      if event == fk.GameStart then return true end
      if event == fk.EventAcquireSkill then return data == self and target == player and player.room:getTag("RoundCount") end
      return target == player
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local x = player:getLostHp() // 5
    if event == fk.DamageCaused then
      room:recover { num = x, skillName = self.name, who = player, recoverBy = player}
    elseif event == fk.DamageInflicted or event == fk.RoundEnd then
      room:loseHp(player, x, self.name)
    else
      for _, p in ipairs(room:getOtherPlayers(player)) do
        if not p.dead then
          room:killPlayer({ who = p.id })
        end
      end
    end
  end
}
joy__nvwa:addSkill(joy__butian)
local joy__lianshi = fk.CreateTriggerSkill{
  name = "joy__lianshi",
  frequency = Skill.Compulsory,
  events = { fk.AfterCardsMove },
  can_trigger = function(self, event, target, player, data)
    if player:hasSkill(self) then
      local mark = U.getMark(player, "@joy__lianshi")
      local suits, num = {}, 0
      for _, move in ipairs(data) do
        if move.from == player.id and (move.moveReason == fk.ReasonUse or move.moveReason == fk.ReasonResonpse or move.moveReason == fk.ReasonDiscard) then
          for _, info in ipairs(move.moveInfo) do
            local card = Fk:getCardById(info.cardId)
            if card.suit ~= Card.NoSuit and not table.contains(mark, card:getSuitString(true)) and (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerHand) then
              num = math.max(num, card.number)
              table.insertIfNeed(suits, card:getSuitString(true))
            end
          end
        end
      end
      if #suits > 0 then
        self.cost_data = {suits, num}
        return true
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    local suits, num = table.unpack(self.cost_data)
    local mark = U.getMark(player, "@joy__lianshi")
    table.insertTable(mark, suits)
    room:setPlayerMark(player, "@joy__lianshi", mark)
    if #mark == 4 then
      player:drawCards(1, self.name)
      room:recover { num = num, skillName = self.name, who = player, recoverBy = player}
      room:setPlayerMark(player, "@joy__lianshi", 0)
    end
  end,
}
local joy__lianshi_maxcards = fk.CreateMaxCardsSkill{
  name = "#joy__lianshi_maxcards",
  fixed_func = function(self, player)
    if player:hasSkill(joy__lianshi) then
      return 5
    end
  end
}
joy__lianshi:addRelatedSkill(joy__lianshi_maxcards)
joy__nvwa:addSkill(joy__lianshi)
local joy__tuantu = fk.CreateActiveSkill{
  name = "joy__tuantu",
  anim_type = "drawcard",
  card_num = 0,
  target_num = 0,
  card_filter = Util.FalseFunc,
  can_use = function(self, player)
    return player:usedSkillTimes(self.name, Player.HistoryPhase) == 0 and not player:isKongcheng()
  end,
  on_use = function(self, room, effect)
    local player = room:getPlayerById(effect.from)
    local get, map = {}, {}
    for _, id in ipairs(player.player_cards[Player.Hand]) do
      map[Fk:getCardById(id).trueName] = {}
    end
    for _, id in ipairs(room.discard_pile) do
      local name = Fk:getCardById(id).trueName
      if map[name] then
        table.insert(map[name], id)
      end
    end
    for _, cards in pairs(map) do
      if #cards > 0 then
        table.insert(get, table.random(cards))
      end
    end
    if #get > 0 then
      room:moveCardTo(get, Card.PlayerHand, player, fk.ReasonPrey, self.name, nil, true, player.id)
    end
  end,
}
joy__nvwa:addSkill(joy__tuantu)
Fk:loadTranslationTable{
  ["joy__nvwa"] = "女娲",
  ["#joy__nvwa"] = "创世女神",
  ["joy__butian"] = "补天",
  [":joy__butian"] = "锁定技，你对其他角色造成伤害时，回复X点体力。每轮结束时，或你受到伤害时，你失去X点体力。当你体力值等于体力上限时，令所有其他角色依次死亡（X为你已损失体力的20%，向下取整）。",
  ["joy__lianshi"] = "炼石",
  [":joy__lianshi"] = "锁定技，你的手牌上限基数为5；每当你使用、打出或弃置牌时，记录此牌花色，然后若已记录四种花色，你摸一张牌并回复X点体力，然后清空花色记录（X为最后记录的花色对应的牌的点数，对应多张牌时取最高值）。",
  ["@joy__lianshi"] = "炼石",
  ["joy__tuantu"] = "抟土",
  [":joy__tuantu"] = "出牌阶段限一次，你可以从弃牌堆获得与手牌中牌名相同的牌各一张。",

  ["$joy__butian1"] = "断鳌足，以立四极！",
  ["$joy__butian2"] = "洪水涸，九州平！",
  ["$joy__lianshi1"] = "采五方，凝五色，炼石补天，定胜万难！",
  ["$joy__lianshi2"] = "五色蕴华，万物化生！",
  ["$joy__tuantu1"] = "抟黄土作人，力不暇供！",
  ["$joy__tuantu2"] = "引绳于泥中，举以为人！",
}

local joy__xiaoshan = General(extension, "joy__xiaoshan", "qun", 3, 3, General.Female)

local joy__shanshan = fk.CreateViewAsSkill{
  name = "joy__shanshan",
  anim_type = "defensive",
  pattern = "jink",
  card_filter = function(self, to_select, selected)
    return #selected == 0 and Fk:getCardById(to_select).type == Card.TypeEquip
  end,
  view_as = function(self, cards)
    if #cards ~= 1 then return nil end
    local c = Fk:cloneCard("jink")
    c.skillName = self.name
    c:addSubcard(cards[1])
    return c
  end,
}
local joy__shanshan_trigger = fk.CreateTriggerSkill{
  name = "#joy__shanshan_trigger",
  mute = true,
  main_skill = joy__shanshan,
  events = {fk.TargetConfirming},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    return data.from ~= player.id and target == player and player:hasSkill(joy__shanshan) and (data.card.trueName == "slash" or data.card:isCommonTrick())
  end,
  on_cost = function (self, event, target, player, data)
    local card = player.room:askForResponse(player, "jink", "jink", "#joy__shanshan-card:::"..data.card:toLogString(), true)
    if card then
      self.cost_data = card
      return true
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    room:responseCard{
      from = player.id,
      card = self.cost_data,
    }
    table.insertIfNeed(data.nullifiedTargets, player.id)
    if not player.dead then
      player:drawCards(1, joy__shanshan.name)
    end
  end,
}
joy__shanshan:addRelatedSkill(joy__shanshan_trigger)
joy__xiaoshan:addSkill(joy__shanshan)

local joy__anshi = fk.CreateTriggerSkill{
  name = "joy__anshi",
  anim_type = "control",
  events = {fk.RoundStart, fk.CardUsing, fk.CardResponding, fk.AfterCardsMove, fk.TargetSpecifying, fk.RoundEnd},
  frequency = Skill.Compulsory,
  can_trigger = function(self, event, target, player, data)
    if not player:hasSkill(self) then return end
    if event == fk.RoundStart then return true end
    local mark = player:getMark("@[joy__anshi]joy__anshi-round")
    if not mark then return end
    if event == fk.AfterCardsMove then
      if mark ~= 3 then return end
      local list = {}
      for _, move in ipairs(data) do
        if move.to and move.toArea == Card.PlayerEquip then
          table.insertIfNeed(list, move.to)
        end
        if move.from and table.find(move.moveInfo, function(info) return info.fromArea == Card.PlayerEquip end) then
          table.insertIfNeed(list, move.from)
        end
      end
      list = table.filter(list, function(pid) return #player.room:getPlayerById(pid).player_cards[Player.Equip] > 0 end)
      if #list > 0 then
        player.room:sortPlayersByAction(list)
        self.cost_data = list
        return true
      end
    elseif event == fk.TargetSpecifying then
      return mark == 5 and data.card.type == Card.TypeTrick and data.firstTarget
    elseif event == fk.RoundEnd then
      return mark == 2
    else
      if mark == 1 then
        return not target.dead and data.card.name == "jink"
      elseif mark == 4 then
        return not target.dead and (data.card.name == "peach" or data.card.name == "analeptic")
        and event == fk.CardUsing
      end
    end
  end,
  on_use = function(self, event, target, player, data)
    local room = player.room
    if event == fk.RoundStart then
      local n = math.random(5)
      room:setPlayerMark(player, "@[joy__anshi]joy__anshi-round", n)
    else
      local mark = player:getMark("@[joy__anshi]joy__anshi-round")
      if mark == 1 then
        target:throwAllCards("h")
      elseif mark == 2 then
        local players = table.filter(room:getAlivePlayers(), function (p)
          return #room.logic:getEventsOfScope(GameEvent.UseCard, 1, function(e)
            return e.data[1].from == p.id and e.data[1].card.name == "jink"
          end, Player.HistoryRound) == 0
          and
          #room.logic:getEventsOfScope(GameEvent.RespondCard, 1, function(e)
            return e.data[1].from == p.id and e.data[1].card.name == "jink"
          end, Player.HistoryRound) == 0
          and
          #room.logic:getEventsOfScope(GameEvent.MoveCards, 1, function(e)
            for _, move in ipairs(e.data) do
              if move.from == p.id and move.moveReason == fk.ReasonDiscard then
                for _, info in ipairs(move.moveInfo) do
                  if (info.fromArea == Card.PlayerHand or info.fromArea == Card.PlayerEquip)
                  and Fk:getCardById(info.cardId).name == "jink" then
                    return true
                  end
                end
              end
            end
          end, Player.HistoryRound) == 0
        end)
        for _, p in ipairs(players) do
          if not p.dead then
            room:damage { from = nil, to = p, damage = 1, skillName = self.name, damageType = fk.ThunderDamage }
          end
        end
      elseif mark == 3 then
        for _, pid in ipairs(self.cost_data) do
          room:getPlayerById(pid):throwAllCards("e")
        end
      elseif mark == 4 then
        room:setPlayerMark(target, "@@joy__anshi_prohibit-turn", 1)
      elseif mark == 5 then
        player:drawCards(1, self.name)
      end
    end
  end,
}
local joy__anshi_prohibit = fk.CreateProhibitSkill{
  name = "#joy__anshi_prohibit",
  prohibit_response = function(self, player, card)
    if player:getMark("@@joy__anshi_prohibit-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player.player_cards[Player.Hand], id)
      end)
    end
  end,
  prohibit_use = function(self, player, card)
    if player:getMark("@@joy__anshi_prohibit-turn") > 0 then
      local subcards = card:isVirtual() and card.subcards or {card.id}
      return #subcards > 0 and table.every(subcards, function(id)
        return table.contains(player.player_cards[Player.Hand], id)
      end)
    end
  end,
}
joy__anshi:addRelatedSkill(joy__anshi_prohibit)
joy__xiaoshan:addSkill(joy__anshi)

-- 临时使用 待 private mark优化后再做处理
Fk:addQmlMark{
  name = "joy__anshi",
  qml_path = "",
  how_to_show = function(name, value, p)
    if Self == p then
      return tostring(value)
    end
    return " "
  end,
}

Fk:loadTranslationTable{
  ["joy__xiaoshan"] = "小闪",

  ["joy__shanshan"] = "闪闪",
  [":joy__shanshan"] = "当你成为其他角色【杀】或普通锦囊的目标时，你可以打出一张【闪】，令此牌对你无效，并摸一张牌。你的装备牌可以当作【闪】使用或打出。",
  ["#joy__shanshan_trigger"] = "闪闪",
  ["#joy__shanshan-card"] = "闪闪：你可以打出一张【闪】，令%arg对你无效",

  ["joy__anshi"] = "暗示",
  [":joy__anshi"] = "锁定枝，每轮开始时，随机选取下列一项效果，于本轮中对每名角色生效（对你可见）："..
  "<br>①使用或打出【闪】时，弃置所有手牌；"..
  "<br>②本轮结束时，未使用、打出、弃置过【闪】的角色依次受到1点雷电伤害；"..
  "<br>③装备区牌数变化后，弃置装备区所有牌；"..
  "<br>④使用【桃】或【酒】时，本回合不能使用或打出手牌；"..
  "<br>⑤使用普通锦囊牌指定目标时，你模一张牌。",
  ["@[joy__anshi]joy__anshi-round"] = "暗示",
  ["@@joy__anshi_prohibit-turn"] = "暗示封牌",

  ["$joy__shanshan1"] = "你等着，略略略~",
  ["$joy__shanshan2"] = "我闪！",
  ["$joy__anshi1"] = "女孩的心思，别猜~",
  ["$joy__anshi2"] = "一个小小的惊喜！",
  ["~joy__xiaoshan"] = "时间已到，闪人咯！",
}



return extension
