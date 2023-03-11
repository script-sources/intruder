type KeyPickerMode = "Always" | "Toggle" | "Hold"

type KeyPicker = {
	Value: string,
	Toggled: boolean,
	Mode: KeyPickerMode,
	SyncToggleState: boolean,
	GetState: (KeyPicker) -> boolean,
	SetValue: (KeyPicker, value: string) -> nil,
	OnClick: (KeyPicker, callback: () -> nil) -> nil,
}
type ColorPicker = {
	Title: string,
	Value: Color3,
	SetValueRGB: (ColorPicker, color: Color3) -> nil,
}

type AddonsContainer = {
	AddKeyPicker: (
		AddonsContainer,
		idx: string,
		options: {
			Text: string,
			Default: string,
			SyncToggleState: boolean,
			Mode: KeyPickerMode,
			NoUI: boolean,
		}
	) -> KeyPicker,
	AddColorPicker: (AddonsContainer, idx: string, options: {
		Title: string,
		Default: Color3,
	}) -> ColorPicker,
}

type SubButton = {}
type Label = AddonsContainer & {}
type Input = {}
type Button = {}
type Toggle = AddonsContainer & {}
type Slider = {}
type Dropdown = {}

type Container = {
	AddLabel: (Container, text: string) -> Label,
	AddDivider: (Container) -> nil,

	AddInput: (
		Container,
		idx: string,
		options: {
			Default: string,
			Numeric: boolean,
			Finished: boolean,
			Text: string,
			Tooltip: string,
			Placeholder: string,
		}
	) -> Input,

	AddButton: (
		Container,
		options: {
			Text: string,
			Func: () -> nil,
			DoubleClick: boolean,
			Tooltip: string,
		}
	) -> Button,

	AddToggle: (
		Container,
		index: string,
		options: {
			Text: string,
			Default: boolean,
			Tooltip: string,
		}
	) -> Toggle,

	AddSlider: (
		Container,
		idx: string,
		options: {
			Text: string,
			Default: number,
			Min: number,
			Max: number,
			Suffix: string,
			Rounding: number,
			Compact: boolean,
			HideMax: boolean,
		}
	) -> Slider,

	AddDropdown: (
		Container,
		idx: string,
		options: {
			Values: { [number]: string },
			Default: number,
			Multi: boolean,
			Text: string,
			Tooltip: string,
		}
	) -> Dropdown,
}

type Groupbox = Container & {}
type Tabbox = {
	AddTab: (Tabbox, title: string) -> Container,
}

type Tab = {
	AddLeftGroupbox: (Tab, title: string) -> Groupbox,
	AddRightGroupbox: (Tab, title: string) -> Groupbox,

	AddLeftTabbox: (Tab, title: string) -> Tabbox,
	AddRightTabbox: (Tab, title: string) -> Tabbox,
}

type Window = {
	SetWindowTitle: (Window, title: string) -> nil,
	AddTab: (Window, title: string) -> Tab,
}

export type Linoria = {
	ToggleKeybind: KeyPicker,

	Unload: (Linoria) -> nil,
	OnUnload: (Linoria, callback: () -> nil) -> nil,
	SetWatermark: (Linoria, text: string) -> nil,
	SetWatermarkVisibility: (Linoria, visible: boolean) -> nil,

	CreateWindow: (Linoria, info: {
		Title: string?,
		Center: boolean?,
		AutoShow: boolean?,
	}) -> Window,
}
