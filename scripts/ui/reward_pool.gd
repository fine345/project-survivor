extends Node

# ============================================================
# 属性提升类
# ============================================================
const ATTRIBUTES := [
	{
		"id": "bullet_damage",
		"name": "练练字吧",
		"detail": "子弹伤害 +30%",
		"type": "attribute",
		"max_count": 5,
		"weight": 1.0
	},
	{
		"id": "pickup_range",
		"name": "读万卷书",
		"detail": "拾取范围 +75%",
		"type": "attribute",
		"max_count": 3,
		"weight": 1.0
	},
	{
		"id": "attack_speed",
		"name": "要写不完了",
		"detail": "攻速 +50%",
		"type": "attribute",
		"max_count": 4,
		"weight": 1.0
	},
	{
		"id": "bullet_count",
		"name": "一心二用",
		"detail": "子弹数量 +1",
		"detail2": "额外子弹效果为第一发的50%",
		"type": "attribute",
		"max_count": 4,
		"weight": 1.0
	},
	{
		"id": "experience_bonus",
		"name": "老师我悟了",
		"detail": "经验球经验 +50%",
		"type": "attribute",
		"max_count": 2,
		"weight": 1.0
	},
	{
		"id": "attack_range",
		"name": "千里眼",
		"detail": "攻击范围 +50%",
		"type": "attribute",
		"max_count": 3,
		"weight": 1.0
	},
	{
		"id": "bullet_speed",
		"name": "笔下生风",
		"detail": "子弹飞行速度 +50%",
		"type": "attribute",
		"max_count": 3,
		"weight": 1.0
	},
]

# ============================================================
# 能力解锁类
# ============================================================
const ABILITIES := [
	{
		"id": "shield",
		"name": "我有假条",
		"detail": "护盾",
		"detail2": "抵挡1次攻击",
		"type": "ability",
		"weight": 1.0
	},
	{
		"id": "freeze_chance",
		"name": "明天再写",
		"detail": "子弹概率冰冻敌人",
		"detail2": "禁锢目标一段时间",
		"type": "ability",
		"max_count": 1,
		"weight": 1.0
	},
	{
		"id": "burn_chance",
		"name": "哪里不会点哪里",
		"detail": "子弹概率点燃敌人",
		"detail2": "造成目标最大血量百分比伤害",
		"type": "ability",
		"max_count": 1,
		"weight": 1.0
	},
	{
		"id": "bounce_count",
		"name": "一箭双雕",
		"detail": "子弹弹射 +1",
		"detail2": "弹射子弹效果为第一发的50%",
		"type": "ability",
		"max_count": 3,
		"weight": 1.0
	},
	{
		"id": "knockback",
		"name": "动量守恒",
		"detail": "子弹获得击退效果",
		"type": "ability",
		"max_count": 1,
		"weight": 1.0
	},
]

# ============================================================
# 武器类 - 旋转尺子
# ============================================================
const WEAPON_RULER := [
	{
		"id": "ruler_weapon",
		"name": "尺子的觉醒",
		"detail": "解锁旋转尺子",
		"type": "weapon",
		"weapon": "ruler",
		"weight": 1.5
	},
	{
		"id": "ruler_count",
		"name": "你尺子借我用用",
		"detail": "旋转尺子 数量 +2",
		"type": "weapon_upgrade",
		"weapon": "ruler",
		"requires": "ruler",
		"max_count": 2,
		"weight": 1.2
	},
	{
		"id": "ruler_damage",
		"name": "划痕加深",
		"detail": "旋转尺子 伤害 +50%",
		"type": "weapon_upgrade",
		"weapon": "ruler",
		"requires": "ruler",
		"max_count": 3,
		"weight": 1.2
	},
	{
		"id": "ruler_radius",
		"name": "扩大作图",
		"detail": "旋转尺子 半径+25%",
		"detail2": "旋转半径+25%",
		"type": "weapon_upgrade",
		"weapon": "ruler",
		"requires": "ruler",
		"max_count": 2,
		"weight": 1.2
	},
	{
		"id": "ruler_speed",
		"name": "飞速旋转",
		"detail": "旋转尺子 旋转速度 +50%",
		"type": "weapon_upgrade",
		"weapon": "ruler",
		"requires": "ruler",
		"max_count": 2,
		"weight": 1.2
	},
]

# ============================================================
# 武器类 - 计算器
# ============================================================
const WEAPON_CALCULATOR := [
	{
		"id": "calculator_weapon",
		"name": "演草纸的救星",
		"detail": "解锁计算器",
		"detail2": "周期发射激光 造成穿透伤害",
		"type": "weapon",
		"weapon": "calculator",
		"weight": 1.5
	},
	{
		"id": "laser_damage",
		"name": "高能运算",
		"detail": "计算器 激光伤害 +50%",
		"type": "weapon_upgrade",
		"weapon": "calculator",
		"requires": "calculator",
		"max_count": 4,
		"weight": 1.2
	},
	{
		"id": "laser_count",
		"name": "并行处理",
		"detail": "计算器 激光个数 +1",
		"type": "weapon_upgrade",
		"weapon": "calculator",
		"requires": "calculator",
		"max_count": 4,
		"weight": 1.2
	},
	{
		"id": "laser_frequency",
		"name": "加速演算",
		"detail": "计算器 发射激光频率 +50%",
		"type": "weapon_upgrade",
		"weapon": "calculator",
		"requires": "calculator",
		"max_count": 2,
		"weight": 1.2
	},
]

# ============================================================
# 合并所有奖励
# ============================================================
var REWARD_DEFS: Array[Dictionary] = []
var _weapon_unlock_ids: Array[String] = []

func _init() -> void:
	REWARD_DEFS.clear()
	REWARD_DEFS.append_array(ATTRIBUTES)
	REWARD_DEFS.append_array(ABILITIES)
	REWARD_DEFS.append_array(WEAPON_RULER)
	REWARD_DEFS.append_array(WEAPON_CALCULATOR)
	for reward in REWARD_DEFS:
		if reward.has("weapon") and reward["type"] == "weapon":
			_weapon_unlock_ids.append(str(reward["id"]))

func get_offer_choices(existing_counts: Dictionary, offer_count: int = 3, player_shield_count: int = 0, player_weapon_flags: Dictionary = {}) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for reward in REWARD_DEFS:
		var reward_id: String = str(reward["id"])
		var current_count: int = int(existing_counts.get(reward_id, 0))
		var max_count: int = int(reward["max_count"]) if reward.has("max_count") else 999999

		if reward_id == "shield":
			if player_shield_count > 0:
				continue
			available.append(reward)
			continue

		if reward.has("requires"):
			var req_id: String = str(reward["requires"])
			if not player_weapon_flags.has(req_id) or not player_weapon_flags[req_id]:
				continue

		if reward.has("type") and reward["type"] == "weapon":
			var weapon_name: String = str(reward.get("weapon", ""))
			if player_weapon_flags.has(weapon_name) and player_weapon_flags[weapon_name]:
				continue

		if current_count < max_count:
			available.append(reward)

	var choices: Array[Dictionary] = []
	var pool: Array[Dictionary] = available.duplicate()
	while choices.size() < offer_count and pool.size() > 0:
		var total_weight := 0.0
		for reward in pool:
			total_weight += _get_weight(reward)
		var roll := randf() * total_weight
		var cumulative := 0.0
		var picked_index := 0
		for i in range(pool.size()):
			cumulative += _get_weight(pool[i])
			if roll <= cumulative:
				picked_index = i
				break
		choices.append(pool[picked_index])
		pool.remove_at(picked_index)
	return choices

func get_reward_title(reward_id: String, existing_count: int = 0) -> String:
	for reward in REWARD_DEFS:
		if reward.id == reward_id:
			if reward_id == "bullet_count" and existing_count >= 1:
				var nums := ["", "二", "三", "四", "五", "六", "七", "八", "九", "十"]
				var idx := mini(existing_count + 1, nums.size() - 1)
				return "一心%s用" % nums[idx]
			if reward_id == "bounce_count" and existing_count >= 1:
				var nums := ["", "双", "三", "四", "五", "六", "七", "八", "九", "十"]
				var idx := mini(existing_count + 1, nums.size() - 1)
				return "一箭%s雕" % nums[idx]
			return str(reward.name)
	return reward_id

func get_reward_detail(reward_id: String) -> String:
	for reward in REWARD_DEFS:
		if reward.id == reward_id:
			return str(reward.get("detail", ""))
	return ""

func get_reward_detail2(reward_id: String) -> String:
	for reward in REWARD_DEFS:
		if reward.id == reward_id:
			return str(reward.get("detail2", ""))
	return ""

func _get_weight(reward: Dictionary) -> float:
	if reward.has("weight"):
		return float(reward["weight"])
	var rtype: String = str(reward.get("type", ""))
	if rtype == "weapon":
		return 1.5
	if rtype == "weapon_upgrade":
		return 1.2
	return 1.0

func get_reward_type(reward_id: String) -> String:
	for reward in REWARD_DEFS:
		if reward.id == reward_id:
			return str(reward.type)
	return "attribute"
