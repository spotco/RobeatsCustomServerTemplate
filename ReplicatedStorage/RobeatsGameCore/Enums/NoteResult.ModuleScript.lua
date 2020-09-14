local NoteResult = {
	Miss = 0;
	Okay = 1;
	Great = 2;
	Perfect = 3;
}

function NoteResult:timedelta_to_result(time_to_end, _game)
	local note_okay_max, note_great_max, note_perfect_max, note_perfect_min, note_great_min, note_okay_min = _game._audio_manager:get_note_result_timing()
	if time_to_end >= note_okay_min and time_to_end <= note_okay_max then
		local note_result
		if time_to_end > note_okay_min and time_to_end <= note_great_min then
			note_result = NoteResult.Okay
		elseif time_to_end > note_great_min and time_to_end <= note_perfect_min then
			note_result = NoteResult.Great
		elseif time_to_end > note_perfect_min and time_to_end <= note_perfect_max then
			note_result = NoteResult.Perfect
		elseif time_to_end > note_perfect_max and time_to_end <= note_great_max then
			note_result = NoteResult.Great
		else
			note_result = NoteResult.Okay
		end
		return true, note_result
	end	
	
	return false, NoteResult.Miss
end

return NoteResult
