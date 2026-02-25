sealed class SmartTeacherState {
  const SmartTeacherState();
}

class SmartTeacherInitial extends SmartTeacherState {
  const SmartTeacherInitial();
}

class SmartTeacherLoading extends SmartTeacherState {
  const SmartTeacherLoading();
}

class SmartTeacherExplanation extends SmartTeacherState {
  const SmartTeacherExplanation(this.text);
  final String text;
}

class SmartTeacherQuestions extends SmartTeacherState {
  const SmartTeacherQuestions(this.questions);
  final String questions;
}

class SmartTeacherAnswer extends SmartTeacherState {
  const SmartTeacherAnswer(this.answer);
  final String answer;
}

class SmartTeacherSpeaking extends SmartTeacherState {
  const SmartTeacherSpeaking();
}

class SmartTeacherPaused extends SmartTeacherState {
  const SmartTeacherPaused();
}

class SmartTeacherFeedback extends SmartTeacherState {
  const SmartTeacherFeedback(this.feedback);
  final String feedback;
}

class SmartTeacherStudyTips extends SmartTeacherState {
  const SmartTeacherStudyTips(this.tips);
  final String tips;
}

class SmartTeacherError extends SmartTeacherState {
  const SmartTeacherError(this.message);
  final String message;
}
