import 'package:flutter/material.dart';

class WalkthroughStepWidget extends StatefulWidget {
  final String question;
  final String? tipTitle;
  final List<String> options;
  final String? tipBody;
  final int currentStep;
  final int totalSteps;

  final String? selectedValue;
  final void Function(String) onSelect;

  final VoidCallback onBack;
  final VoidCallback onContinue;

  const WalkthroughStepWidget({
    super.key,
    required this.question,
    required this.options,
    required this.currentStep,
    required this.totalSteps,
    required this.onSelect,
    required this.onBack,
    required this.onContinue,
    this.tipTitle,
    this.tipBody,
    this.selectedValue,
  });

  @override
  State<WalkthroughStepWidget> createState() => _WalkthroughStepWidgetState();
}

class _WalkthroughStepWidgetState extends State<WalkthroughStepWidget> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.totalSteps, (i){
                  final active = i == widget.currentStep;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 12 : 8,
                    height: active ? 12 : 8,
                    decoration: BoxDecoration(
                      color: active ? Colors.blue : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 30),
              Text(
                widget.question,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ...widget.options.map((opt) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () => widget.onSelect(opt),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.selectedValue == opt ? Colors.blue : Colors.grey,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.selectedValue == opt
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: widget.selectedValue == opt ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            opt,
                            style: const TextStyle(fontSize: 17),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 20),
              if (widget.tipTitle != null)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lightbulb_outline),
                      title: Text(
                        widget.tipTitle!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: Icon(
                        expanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                      onTap: () => setState(() {
                          expanded = !expanded;
                        }),
                    ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 200),
                      crossFadeState: expanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: Container(),
                      secondChild: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          widget.tipBody ?? "",
                          style: const TextStyle(fontSize: 15, height: 1.4),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  TextButton(
                    onPressed: widget.onBack,
                    child: const Text("Back"),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: widget.selectedValue == null ? null : widget.onContinue,
                    child: const Text("Continue"),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }
}