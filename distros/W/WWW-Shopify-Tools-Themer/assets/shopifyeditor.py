from gettext import gettext as _
from gi.repository import GObject, Gtk, Gedit, PeasGtk
import time, threading, subprocess, re, json, os, hashlib, urllib2, sys

ui_str = """<ui>
  <menubar name="MenuBar">
    <menu name="ToolsMenu" action="Tools">
      <placeholder name="ToolsOps_2">
        <menuitem name="ShopifyNewProject" action="ShopifyNewProject"/>
        <menuitem name="ShopifyOpenProject" action="ShopifyOpenProject"/>
      </placeholder>
    </menu>
  </menubar>
</ui>
"""

class ShopifyEditorPlugin(GObject.Object, Gedit.WindowActivatable):
	__gtype_name__ = "ShopifyEditorPyPlugin"

	window = GObject.property(type=Gedit.Window)


	def __init__(self):
		GObject.Object.__init__(self)
		self.projects = {}
		self.save_directory = os.path.dirname(__file__)
		self.exec_directory = os.path.dirname(__file__)

	def do_activate(self):
		self._insert_menu()
		files = []
		try:
			with open(self.save_directory + '/' + '.saved') as f:
				files = json.loads(f.read())
		except IOError as e:
			pass
		for f in files:
			project = ShopifyProject(self)
			try:
				project.enable_file(f)
				self.register_project(project)
			except IOError as e:
				pass;
	
	def show_error(self, message):
		md = gtk.MessageDialog(self, gtk.DIALOG_DESTROY_WITH_PARENT, gtk.MESSAGE_INFO, gtk.BUTTONS_ERROR, message)
		md.run()
		md.destroy()

		
	def get_project_directories(self):
		return self.projects.keys()

	def do_deactivate(self):
		self._remove_menu()
		self._action_group = None
		try:
			with open(self.save_directory + '/' + '.saved', 'w') as f:
				f.write(json.dumps(self.get_project_directories()))
		except IOError as e:
			pass
		
		for project in self.projects.values():
			project.cleanup()
		projects = {}

	def do_update_state(self):
		pass

	def _insert_menu(self):
		manager = self.window.get_ui_manager()
		self._action_group = Gtk.ActionGroup("ShopifyPluginActions")
		self._action_group.add_actions([("ShopifyNewProject", None, _("Add Shopify Project"), '<Ctrl><Alt>A', _("Add a new Shopify Project"), self.on_add_project_activate)])
		self._action_group.add_actions([("ShopifyOpenProject", None, _("Open Shopify Project"), '<Ctrl><Alt>E', _("Open an existing Shopify Project"), self.on_open_project_activate)])
		self._action_group.add_actions([("ShopifyPullProject", None, _("Pull Shopify Project"), '<Ctrl><Alt>P', _("Pull all from the current Shopify Project"), self.on_pull_project_activate)])
		self._action_group.add_actions([("ShopifyPushProject", None, _("Push Shopify Project"), '<Ctrl><Alt>S', _("Push all from the current Shopify Project"), self.on_push_project_activate)])
		manager.insert_action_group(self._action_group, -1)
		self._ui_id = manager.add_ui_from_string(ui_str)

	def on_push_project_activate(self, action):
		active_project = self.get_active_project()
		if active_project != None:
			active_project.disable_buttons()
			active_project.push()
		else:
			dialog = Gtk.Dialog("No Active Project", self.window)
			dialog.add_buttons(Gtk.STOCK_CLOSE, Gtk.ResponseType.CANCEL)
			dialog.get_content_area().add_item(Gtk.Label("Unable to push project, no project selected."))
			dialog.run()
			dialog.destroy()

	def on_pull_project_activate(self, action):
		active_project = self.get_active_project()
		if active_project != None:
			active_project.disable_buttons()
			active_project.pull()
		else:
			dialog = Gtk.Dialog("No Active Project", self.window)
			dialog.add_buttons(Gtk.STOCK_CLOSE, Gtk.ResponseType.CANCEL)
			dialog.get_content_area().add_item(Gtk.Label("Unable to push project, no project selected."))
			dialog.run()
			dialog.destroy()

	def _remove_menu(self):
		manager = self.window.get_ui_manager()
		manager.remove_ui(self._ui_id)
		manager.remove_action_group(self._action_group)
		manager.ensure_update()

	def on_add_project_activate(self, action):
		file_chooser = Gtk.FileChooserDialog("Create Project", self.window, Gtk.FileChooserAction.SELECT_FOLDER, 
			(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_ADD, Gtk.ResponseType.OK))
		response = file_chooser.run()
		if response == Gtk.ResponseType.OK:
			directory = file_chooser.get_filename()
			file_chooser.destroy()
			dialog = Gtk.Dialog("Create Project", self.window)
			dialog.set_size_request(500, -1)
			dialog.add_buttons(Gtk.STOCK_ADD, Gtk.ResponseType.OK, Gtk.STOCK_CLOSE, Gtk.ResponseType.CANCEL)
			box = dialog.get_content_area()

			shop_name_entry = Gtk.Entry()
			shop_url_entry = Gtk.Entry()
			shop_url_entry.set_max_length(100)
			shop_api_key_entry = Gtk.Entry()
			shop_api_key_entry.set_max_length(32)
			shop_password_entry = Gtk.Entry()
			shop_password_entry.set_max_length(32)

			table = Gtk.Table(5, 2)
			table.attach(Gtk.Label("Project Name"), 0, 1, 0, 1)
			table.attach(shop_name_entry, 1, 2, 0, 1)
			table.attach(Gtk.Label("Site URL"), 0, 1, 1, 2)
			table.attach(shop_url_entry, 1, 2, 1, 2)

			combo_box = Gtk.ComboBoxText()
			combo_box.append_text("API Key")
			combo_box.append_text("Email")
			combo_box.set_active(0)

			table.attach(combo_box, 0, 1, 2, 3)
			table.attach(shop_api_key_entry, 1, 2, 2, 3)
			table.attach(Gtk.Label("Password"), 0, 1, 3, 4)
			table.attach(shop_password_entry, 1, 2, 3, 4)
			box.add(table)
			box.show_all()

			response = dialog.run()

			if response == Gtk.ResponseType.OK:
				project = ShopifyProject(self)
				if combo_box.get_active() == 0:
					project.enable_settings(shop_name_entry.get_text(), shop_url_entry.get_text(), shop_api_key_entry.get_text(), None, shop_password_entry.get_text(), directory)
				else:
					project.enable_settings(shop_name_entry.get_text(), shop_url_entry.get_text(), None, shop_api_key_entry.get_text(), shop_password_entry.get_text(), directory)
				self.register_project(project)
			dialog.destroy()
		elif response == Gtk.ResponseType.CANCEL:
			file_chooser.destroy()

	def on_open_project_activate(self, action):
		file_chooser = Gtk.FileChooserDialog("Open Exiting Project", self.window, Gtk.FileChooserAction.SELECT_FOLDER,
			(Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL, Gtk.STOCK_OPEN, Gtk.ResponseType.OK))
		response = file_chooser.run()
		if response == Gtk.ResponseType.OK:
			project = ShopifyProject(self)
			try:
				project.enable_file(file_chooser.get_filename())
				self.register_project(project)
			except IOError as e:
				self.show_error("Unable to find an existing project in this folder.")
		file_chooser.destroy()

	def register_project(self, project):
		self.projects[project.settings['directory']] = project
		self.active_project = project
		self.window.get_bottom_panel().set_property("visible", True)

	def unregister_project(self, project):
		del self.projects[project.settings['directory']]

	def get_active_project(self):
		active_project = None
		for project in projects.values():
			if self.window.get_bottom_panel().is_active_item(project.fullbox):
				active_project = project
		return active_project


class ShopifyProject():
	def __init__(self, plugin):
		self.plugin = plugin
		self.fullbox = None
		self.is_busy = 0
	def __del__(self):
		self.cleanup()

	def cleanup(self):
		self.plugin.unregister_project(self)
		self.remove_menu()
		if self.shop_themer != None:
			self.shop_themer.kill()
			self.shop_themer = None

	# Creates the appropriate arguments for a script.
	def themer_arguments(self, action, argument = None):
		# Seriously Pyhton? It's possible I'm not doing it right, but damn, that array manipulation is cumbersome.
		arguments = ['shopify-themer.pl', '--wd=' + os.path.abspath(self.settings['directory']), '--password=' + self.settings['password'], '--url=' + self.settings['url'], action]
		if argument != None:
			arguments.append(argument)
		if self.settings['email'] != None:
			arguments.append('--email=' + self.settings['email'])
		else:
			arguments.append('--api_key=' + self.settings['api_key'])
		return arguments

	# Enable the project by loading a settings file in the specified directory.
	def enable_file(self, directory):
		settings = {}
		with open(directory + '/' + '.shopifygedit') as f:
			settings = json.loads(f.read())
		self.enable_settings(settings['name'], settings['url'], settings['api_key'], settings['email'], settings['password'], directory)
	
	# Enables the project through arguments.
	def enable_settings(self, name, url, api_key, email, password, directory):
		self.remove_menu()
		self.settings = {'name': name, 'url': url, 'email': email, 'api_key': api_key, 'password': password, 'directory': directory}
		try:
			with open(directory + '/' + '.shopifygedit', 'w') as f:
				f.write(json.dumps(self.settings))
		except IOError as e:
			print 'Unable to open file: ' + directory + '/' + '.shopifygedit'
		self.insert_menu()
		self.shop_themer = subprocess.Popen(self.themer_arguments("interactive"), stdout=subprocess.PIPE, stdin=subprocess.PIPE)

	def update_theme_listing(self):
		#self.theme_selector.clear_items()
		self.theme_selector.append_text("<< ALL >>")
		self.theme_selector.set_active(0)
		try:
			theme_json = subprocess.check_output(self.themer_arguments('info'))
			themes = eval(re.sub(r'^Done.$', r'', theme_json, flags=re.MULTILINE))
			for i in themes:
				self.theme_selector.append_text(i['name'])
		except subprocess.CalledProcessError as e:
			md = Gtk.MessageDialog(self.plugin.window, 0, Gtk.MessageType.ERROR, Gtk.ButtonsType.CLOSE, "There was an error. Make sure you have the right credentials. Check your terminal for more detailed output. " + e.output)
			md.run()
			md.destroy()

	def insert_menu(self):
		self.fullbox = Gtk.HBox()
		self.toolbox = Gtk.VBox()
		self.top_box = Gtk.HBox()
		self.pull_button = Gtk.Button()
		pull_image = Gtk.Image()
		pull_image.set_from_file(self.plugin.save_directory + '/pull.png')
		self.pull_button.set_image(pull_image)
		self.pull_button.set_tooltip_text("Pull all repositories from this project's repository.")
		self.pull_button.connect("button-press-event", self.on_pull_button_activate)
		self.push_button = Gtk.Button()
		push_image = Gtk.Image()
		push_image.set_from_file(self.plugin.save_directory + '/push.png')
		self.push_button.set_image(push_image)
		self.push_button.set_tooltip_text("Push all repositories to this project's repository.")
		self.push_button.connect("button-press-event", self.on_push_button_activate)
		refresh_image = Gtk.Image()
		refresh_image.set_from_file(self.plugin.save_directory + '/refresh.png')
		self.refresh_button = Gtk.ToggleButton()
		self.refresh_button.set_image(refresh_image)
		self.refresh_button.set_tooltip_text("Push on save.")
		self.refresh_button.connect("button-press-event", self.on_refresh_button_activate)

		self.theme_selector = Gtk.ComboBoxText()
		self.update_theme_listing()

		self.status_label = Gtk.Label()
		self.progress_bar = Gtk.ProgressBar()
		self.top_box.pack_start(self.pull_button, False, False, 0)
		self.top_box.pack_start(self.push_button, False, False, 0)
		self.top_box.pack_start(self.refresh_button, False, False, 0)
		self.top_box.pack_start(self.theme_selector, False, False, 0)
		self.top_box.pack_start(self.status_label, True, True, 0)
		self.toolbox.pack_start(self.top_box, True, True, 0)
		self.toolbox.pack_start(self.progress_bar, True, True, 0)
		self.close_button = Gtk.Button()
		close_image = Gtk.Image()
		close_image.set_from_stock(Gtk.STOCK_CLOSE, 1)
		self.close_button.set_image(close_image)
		self.close_button.connect("button-press-event", self.on_close_button_activate)
		self.fullbox.pack_start(self.close_button, False, False, 0)
		self.fullbox.pack_start(self.toolbox, True, True, 0)
		self.plugin.window.get_bottom_panel().add_item(self.fullbox, self.settings['name'], self.settings['name'], None)
		self.plugin.window.get_bottom_panel().activate_item(self.fullbox)
		self.fullbox.show_all()

	def remove_menu(self):
		if self.fullbox != None:
			self.plugin.window.get_bottom_panel().remove_item(self.fullbox)

	def work(self, argument):
		self.shop_themer.stdin.write(" ".join(argument) + "\n");
		while True:
			line = self.shop_themer.stdout.readline()
			display = line.rstrip("\n")
			m = re.search("^\[(\d+\.\d+)%\] (.*)\n", line)
			self.progress_bar.set_fraction(0.0)
			if m != None:
				real = float(m.group(1)) / 100.0
				self.progress_bar.set_fraction(real)
				display = m.group(2)
			self.status_label.set_text(display)
			if display == "" or display == "Done." or re.search("^Error:", display):
				break
		self.progress_bar.set_fraction(1.0)
		self.enable_buttons()
	
	def disable_buttons(self):
		self.pull_button.set_sensitive(False)
		self.push_button.set_sensitive(False)

	def enable_buttons(self):
		self.pull_button.set_sensitive(True)
		self.push_button.set_sensitive(True)

	def push(self):
		self.disable_buttons()
		self.should_push = 0
		self.is_pushing = 1
		argument_array = []
		if self.theme_selector.get_active_text() == None:
			raise Exception("Should never be None for theme selector active.")
		if self.theme_selector.get_active_text() == "<< ALL >>":
			argument_array = ['pushAll']
		else:
			argument_array = ['push', self.theme_selector.get_active_text()]
		wt = PushThread(self.work, argument_array)
		wt.start()

	def pull(self):
		self.disable_buttons()
		argument_array = []
		if self.theme_selector.get_active_text() == None:
			raise Exception("Should never be None for theme selector active.")
		if self.theme_selector.get_active_text() == "<< ALL >>":
			argument_array = ['pullAll']
		else:
			argument_array = ['pull', self.theme_selector.get_active_text()]
		wt = PullThread(self.work, argument_array)
		wt.start()

	def on_push_button_activate(self, widget, event):
		self.push()

	def on_pull_button_activate(self, widget, event):
		self.pull()

	def on_refresh_button_activate(self, widget, event):
		if widget.get_active:
			self.id_map = {};
			self.refresh_save_id = self.plugin.window.connect("tab-added", self.on_tab_add)
			documents = self.plugin.window.get_documents()
			for d in documents:
				self.id_map[d] = d.connect("saved", self.on_document_save)
		else:
			self.plugin.window.disconnect(self.refresh_save_id)
			for d in self.id_map:
				d.disconect(self.id_map[d])
			self.id_map[d] = {}

	def on_close_button_activate(self, widget, event):
		self.cleanup()
		del self

	def on_tab_add(self, window, tab):
		d = tab.get_document()
		self.id_map[d] = d.connect("saved", self.on_document_save)

	def on_document_save(self, widget, event):
		if self.is_busy == 1:
			self.should_push = 1
		else:
			self.push()
		

class WorkerThread(threading.Thread):
	def __init__ (self, function, argument):
		threading.Thread.__init__(self)
		self.function = function
		self.argument = argument
 
	def run(self):
		self.function(self.argument)
 
	def stop(self):
		self = None
		self.is_pushing = 0

class PullThread(WorkerThread):
	pass

class PushThread(WorkerThread): 
	def stop(self):
		temp = self
		super(C, self).stop(self)
		if temp.should_push:
			temp.push()
		

