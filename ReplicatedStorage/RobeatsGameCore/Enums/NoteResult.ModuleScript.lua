local NoteResult = {
	Miss = 0;
	Okay = 1;
	Great = 2;
	Perfect = 3;
}

function NoteResult:timedelta_to_result(time_to_end, _game)
	if time_to_end >= _game._audio_manager.NOTE_OKAY_MIN and time_to_end <= _game._audio_manager.NOTE_OKAY_MAX then
		local note_result = nil			
		
		if time_to_end > _game._audio_manager.NOTE_OKAY_MIN and time_to_end <= _game._audio_manager.NOTE_GREAT_MIN then
			note_result = NoteResult.Okay						
		elseif time_to_end > _game._audio_manager.NOTE_GREAT_MIN and time_to_end <= _game._audio_manager.NOTE_PERFECT_MIN then
			note_result = NoteResult.Great							
		elseif time_to_end > _game._audio_manager.NOTE_PERFECT_MIN and time_to_end <= _game._audio_manager.NOTE_PERFECT_MAX then
			note_result = NoteResult.Perfect						
		elseif time_to_end > _game._audio_manager.NOTE_PERFECT_MAX and time_to_end <= _game._audio_manager.NOTE_GREAT_MAX then
			note_result = NoteResult.Great					
		else
			note_result = NoteResult.Okay
		end
		
		return true, note_result
	end	
	
	return false, NoteResult.Miss
end

return NoteResult
