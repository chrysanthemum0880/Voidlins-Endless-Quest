extends Node

var gameStarted: bool
var playerBody: CharacterBody2D
var playerWeaponEquip: bool
var playerAlive: bool
var playerDamageZone: Area2D
var playerDamageAmount: int
var voidenemyDamageZone: Area2D
var voidenemyDamageAmount: int
var startgame: bool
var current_wave: int
var moving_to_next_wave: bool
