extends Node

# ============================================================
# 属性提升类
# ============================================================
const ATTRIBUTES := [
	{
		"id": "bullet_damage",
		"title": "子弹伤害 +50%",
		"type": "attribute",
		"max_count": 5
	},
	{
		"id": "pickup_range",
		"title": "拾取范围 +75%",
		"type": "attribute",
		"max_count": 2
	},
	{
		"id": "attack_speed",
		"title": "攻速 +50%",
		"type": "attribute",
		"max_count": 2
	},
	{
		"id": "bullet_count",
		"title": "子弹数量 +1",
		"type": "attribute",
		"max_count": 3
	},
	{
		"id": "experience_bonus",
		"title": "经验球经验 +50%",
		"type": "attribute",
		"max_count": 2
	},
	{
		"id": "attack_range",
		"title": "攻击范围 +50%",
		"type": "attribute",
		"max_count": 2
	},
	{
		"id": "bullet_speed",
		"title": "子弹飞行速度 +50%",
		"type": "attribute",
		"max_count": 2
	},
]

# ============================================================
# 能力解锁类
# ============================================================
const ABILITIES := [
	{
		"id": "shield",
		"title": "护盾（抵挡1次攻击）",
		"type": "ability"
	},
	{
		"id": "freeze_chance",
		"title": "子弹概率冰冻敌人",
		"type": "ability",
		"max_count": 1
	},
	{
		"id": "burn_chance",
		"title": "子弹概率点燃敌人",
		"type": "ability",
		"max_count": 1
	},
	{
		"id": "bounce_count",
		"title": "子弹弹射 +1",
		"type": "ability",
		"max_count": 2
	},
	{
		"id": "knockback",
		"title": "子弹获得击退效果",
		"type": "ability",
		"max_count": 1
	},
]

# ============================================================
# 新武器类 - 旋转尺子
# ============================================================
const WEAPON_RULER := [
	{
		"id": "ruler_weapon",
		"title": "解锁旋转尺子",
		"type": "weapon",
		"weapon": "ruler"
	},
	{
		"id": "ruler_count",
		"title": "旋转尺子 数量 +2",
		"type": "weapon_upgrade",
		"weapon": "ruler",
		"requires": "ruler",
		"max_count": 2
	},
	{
		"id": "ruler_damage",
		"title": "旋转尺子 伤害 +50%",
		"type": "weapon_upgrade",
		"weapon": "ruler",
		"requires": "ruler",
		"max_count": 3
	},
	{
		"id": "ruler_radius",
		"title": "旋转尺子 半径+25% 尺子+25%",
		"type": "weapon_upgrade",
		"weapon": "ruler",
		"requires": "ruler",
		"max_count": 2
	},
	{
		"id": "ruler_speed",
		"title": "旋转尺子 速度 +50%",
		"type": "weapon_upgrade",
		"weapon": "ruler",
		"requires": "ruler",
		"max_count": 2
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
		var index: int = randi() % pool.size()
		choices.append(pool[index])
		pool.remove_at(index)
	return choices

func get_reward_title(reward_id: String) -> String:
	for reward in REWARD_DEFS:
		if reward.id == reward_id:
			return str(reward.title)
	return reward_id

func get_reward_type(reward_id: String) -> String:
	for reward in REWARD_DEFS:
		if reward.id == reward_id:
			return str(reward.type)
	return "attribute"
