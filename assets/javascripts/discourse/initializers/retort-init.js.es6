import { withPluginApi } from "discourse/lib/plugin-api";
import { emojiUrlFor } from "discourse/lib/text";
import Retort from "../lib/retort";
import User from "discourse/models/user";

function initializePlugin(api) {
  const { retort_enabled } = api.container.lookup("site-settings:main");
  
  if (!retort_enabled) {
    return;
  }

  api.decorateWidget("post-contents:after-cooked", (helper) => {
    let postId = helper.getModel().id;
    let post = Retort.postFor(postId);

    if (Retort.disabledForPost(postId)) {
      return;
    }

    Retort.storeWidget(helper);

    if (!post.retorts) {
      return;
    }
    const currentUser = api.getCurrentUser();
    const retorts = post.retorts
      .map((item) => {
        item.emojiUrl = emojiUrlFor(item.emoji);
        return item;
      })
      .filter(({ emojiUrl }) => emojiUrl)
      .sort((a, b) => a.emoji.localeCompare(b.emoji));
    const retort_widgets = retorts.map(({ emoji, emojiUrl, usernames }) =>
      helper.attach("retort-toggle", {
        emoji,
        emojiUrl,
        post,
        usernames,
        currentUser,
      })
    );

    return helper.h("div.post-retort-container", retort_widgets);
  });

  api.addPostClassesCallback((attrs) => {
    if (!Retort.disabledForPost(attrs.id)) {
      return ["retort"];
    }
  });

  if (!User.current()) {
    return;
  }

  api.modifyClass("route:topic", {
    pluginId: "retort",

    setupController(controller, model) {
      const messageBus = api.container.lookup("message-bus:main");
      Retort.initialize(messageBus, model);
      this._super(controller, model);
    },
  });

  api.addPostMenuButton("retort", (attrs) => {
    if (Retort.disabledForPost(attrs.id) || !attrs.canCreatePost) {
      return;
    }
    return {
      action: "clickRetort",
      icon: "far-smile",
      title: "retort.title",
      position: "first",
      className: "retort",
    };
  });

  api.attachWidgetAction("post-menu", "clickRetort", function () {
    const post = this.findAncestorModel()
    Retort.openPicker(post);
  });

  api.registerConnectorClass("above-footer", "emoji-picker-wrapper", {
    setupComponent(args, component) {
      Retort.setPicker(component);
    }
  })
}

export default {
  name: "retort-button",
  initialize: function () {
    withPluginApi("0.8.6", (api) => initializePlugin(api));
  },
};
